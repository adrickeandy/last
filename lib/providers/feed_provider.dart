import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/profile_model.dart';
import '../services/post_service.dart';
import '../services/local_cache_service.dart';

/// Outcome of a like/unlike request (see [FeedProvider.setLike]).
class LikeResult {
  /// False if the server rejected the change (the UI should revert).
  final bool success;

  /// The post's real like count according to the server, when we could get it.
  final int? serverLikeCount;

  const LikeResult({required this.success, this.serverLikeCount});
}

/// Feed state, built offline-first ("WhatsApp method"):
///
/// - On load, cached posts render immediately (instant, works offline).
/// - Refreshing (pull-to-refresh or coming back online) fetches only posts
///   newer than the newest one already held — never the whole table again.
/// - New posts and comments are written to the local cache immediately,
///   before the network call even starts, and are retried automatically
///   if that network call fails while offline — plus a manual [retryPost]
///   / [retryComment] for a "tap to retry" button in the UI.
///
/// A full re-fetch only ever happens once: the very first time the app
/// runs with no cache at all.
class FeedProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final LocalCacheService _cache = LocalCacheService();
  final _uuid = const Uuid();

  List<PostModel> _feedPosts = [];
  List<PostModel> _confessions = [];
  bool _isLoadingFeed = true;
  bool _isLoadingConfessions = true;
  bool _isPosting = false;
  bool _isSyncing = false;
  // True when the most recent sync attempt failed (no connection, server
  // error, etc.) but we still have cached data to show, so the feed isn't
  // left blank — just marked as possibly stale.
  bool _isOffline = false;

  // The account the in-memory feed belongs to. If a different account signs
  // in (same device, same running app) the old feed - including its
  // "liked by me" flags - must be thrown away, not reused.
  String? _activeUserId;

  // Posts with a like request in flight, so a background refresh doesn't
  // overwrite the optimistic state mid-request.
  final Set<String> _likeInFlight = {};

  List<PostModel> get feedPosts => _feedPosts;
  List<PostModel> get confessions => _confessions;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingConfessions => _isLoadingConfessions;
  bool get isPosting => _isPosting;
  bool get isSyncing => _isSyncing;
  bool get isOffline => _isOffline;

  /// Makes sure whatever is cached / in memory belongs to [userId]. Cached
  /// posts store "liked by me" for whoever was signed in at the time, so
  /// showing them to another account made likes look shared between users
  /// (and tapping like would then UNLIKE). Different or unknown owner ->
  /// start clean and refetch.
  Future<void> _ensureCacheBelongsTo(String? userId) async {
    if (userId == null) return;

    final memoryOwnerChanged = _activeUserId != null && _activeUserId != userId;
    final persistedOwner = await _cache.loadCacheOwner();

    if (memoryOwnerChanged || persistedOwner != userId) {
      _feedPosts = [];
      _confessions = [];
      _isLoadingFeed = true;
      _isLoadingConfessions = true;
      await _cache.clearPostCaches();
      await _cache.saveCacheOwner(userId);
      notifyListeners();
    }

    _activeUserId = userId;
  }

  /// Pulls fresh like/comment counters and this user's "liked" flags for
  /// the posts we already hold. Delta sync only downloads NEW posts, so
  /// without this, old posts would keep whatever counts they had when first
  /// cached. Returns true if anything changed.
  Future<bool> _refreshEngagement(List<PostModel> list, String? userId) async {
    final ids = list
        .where((p) => !p.isPending && !p.id.startsWith('local-'))
        .take(100)
        .map((p) => p.id)
        .toList();
    if (ids.isEmpty) return false;

    final stats = await _postService.fetchEngagement(ids);
    final likedIds = userId != null
        ? await _postService.fetchMyLikedPostIds(userId, ids)
        : <String>{};

    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final post = list[i];
      final s = stats[post.id];
      if (s == null || _likeInFlight.contains(post.id)) continue;

      final likeCount = s['like_count'] ?? post.likeCount;
      final commentCount = s['comment_count'] ?? post.commentCount;
      final liked = userId != null ? likedIds.contains(post.id) : false;

      if (likeCount != post.likeCount ||
          commentCount != post.commentCount ||
          liked != post.likedByMe) {
        list[i] = post.copyWith(
          likeCount: likeCount,
          commentCount: commentCount,
          likedByMe: liked,
        );
        changed = true;
      }
    }
    return changed;
  }

  Future<void> loadFeed(String? userId) async {
    await _ensureCacheBelongsTo(userId);

    // Cold start: hydrate instantly from local cache before touching the
    // network, so a slow/offline connection never means a blank screen.
    if (_feedPosts.isEmpty) {
      final cached = await _cache.loadCachedFeed();
      if (cached.isNotEmpty) {
        _feedPosts = cached;
        _isLoadingFeed = false;
        notifyListeners();
      }
    }

    final hadCache = _feedPosts.isNotEmpty;
    _isLoadingFeed = !hadCache;
    _isSyncing = true;
    notifyListeners();

    try {
      if (hadCache) {
        // Delta sync: only ask for what's new since the newest post we
        // already hold, instead of re-downloading the whole feed.
        final newest = _feedPosts
            .where((p) => !p.isPending)
            .map((p) => p.createdAt)
            .fold<String?>(null, (a, b) => (a == null || b.compareTo(a) > 0) ? b : a);

        if (newest != null) {
          final fresh = await _postService.fetchFeedSince(since: newest, currentUserId: userId);
          if (fresh.isNotEmpty) {
            final existingIds = _feedPosts.map((p) => p.id).toSet();
            final trulyNew = fresh.where((p) => !existingIds.contains(p.id)).toList();
            _feedPosts.insertAll(0, trulyNew);
          }
        }
      } else {
        _feedPosts = await _postService.fetchFeed(currentUserId: userId);
      }

      _isOffline = false;

      // Refresh counters + my like flags for posts we already had cached.
      try {
        await _refreshEngagement(_feedPosts, userId);
      } catch (e) {
        print('[FeedProvider] refreshEngagement error: $e');
      }

      await _cache.saveCachedFeed(_feedPosts);
      await _retryPendingPosts(userId);
    } catch (e) {
      print('[FeedProvider] loadFeed error: $e');
      // Keep whatever we already have (cached or previously loaded) —
      // just flag that this refresh didn't succeed.
      _isOffline = _feedPosts.isNotEmpty;
    } finally {
      _isLoadingFeed = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loadConfessions([String? userId]) async {
    await _ensureCacheBelongsTo(userId);

    if (_confessions.isEmpty) {
      final cached = await _cache.loadCachedConfessions();
      if (cached.isNotEmpty) {
        _confessions = cached;
        _isLoadingConfessions = false;
        notifyListeners();
      }
    }

    final hadCache = _confessions.isNotEmpty;
    _isLoadingConfessions = !hadCache;
    notifyListeners();

    try {
      if (hadCache) {
        final newest = _confessions
            .map((p) => p.createdAt)
            .fold<String?>(null, (a, b) => (a == null || b.compareTo(a) > 0) ? b : a);
        if (newest != null) {
          final fresh = await _postService.fetchConfessionsSince(since: newest);
          if (fresh.isNotEmpty) {
            final existingIds = _confessions.map((p) => p.id).toSet();
            final trulyNew = fresh.where((p) => !existingIds.contains(p.id)).toList();
            _confessions.insertAll(0, trulyNew);
          }
        }
      } else {
        _confessions = await _postService.fetchConfessions();
      }

      try {
        await _refreshEngagement(_confessions, userId);
      } catch (e) {
        print('[FeedProvider] refreshEngagement (confessions) error: $e');
      }

      await _cache.saveCachedConfessions(_confessions);
    } catch (e) {
      print('[FeedProvider] loadConfessions error: $e');
    } finally {
      _isLoadingConfessions = false;
      notifyListeners();
    }
  }

  /// Local-first create: the post appears instantly (and survives an app
  /// restart via the cache) before the network call even starts. If the
  /// network call fails — e.g. no connection — the post stays in the feed
  /// marked as pending and is retried automatically on the next successful
  /// [loadFeed] call, or manually via [retryPost].
  Future<bool> createPost({
    required String authorId,
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    bool isConfession = false,
    ProfileModel? authorProfile,
  }) async {
    final tempId = 'local-${_uuid.v4()}';
    final now = DateTime.now().toUtc().toIso8601String();

    final pendingPost = PostModel(
      id: tempId,
      authorId: authorId,
      content: content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      isConfession: isConfession,
      createdAt: now,
      updatedAt: now,
      author: authorProfile,
      isPending: true,
    );

    if (isConfession) {
      _confessions.insert(0, pendingPost);
      await _cache.saveCachedConfessions(_confessions);
    } else {
      _feedPosts.insert(0, pendingPost);
      await _cache.saveCachedFeed(_feedPosts);
    }
    _isPosting = true;
    notifyListeners();

    final synced = await _syncPendingPost(pendingPost, isConfession: isConfession);
    _isPosting = false;
    notifyListeners();
    return synced;
  }

  /// Attempts to push a single pending (locally-created, not-yet-synced)
  /// post to Supabase, replacing it in place with the server-confirmed
  /// version on success. Returns false (without removing the pending post)
  /// if the network call fails, so it can be retried later.
  Future<bool> _syncPendingPost(PostModel pendingPost, {required bool isConfession}) async {
    try {
      final serverPost = await _postService.createPost(
        authorId: pendingPost.authorId,
        content: pendingPost.content ?? '',
        imageUrls: pendingPost.imageUrls,
        videoUrl: pendingPost.videoUrl,
        isConfession: isConfession,
      );

      final list = isConfession ? _confessions : _feedPosts;
      final index = list.indexWhere((p) => p.id == pendingPost.id);
      if (index != -1) {
        list[index] = serverPost;
      }

      if (isConfession) {
        await _cache.saveCachedConfessions(_confessions);
      } else {
        await _cache.saveCachedFeed(_feedPosts);
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('[FeedProvider] Failed to sync pending post ${pendingPost.id}: $e');
      return false;
    }
  }

  /// Called automatically at the start of every successful [loadFeed] —
  /// resends any posts that were created while offline and haven't
  /// reached the server yet.
  Future<void> _retryPendingPosts(String? userId) async {
    final pending = _feedPosts.where((p) => p.isPending).toList();
    for (final post in pending) {
      await _syncPendingPost(post, isConfession: false);
    }
  }

  /// Manual "tap to retry" for a single stuck post — wire this to a retry
  /// icon in PostCard. Returns true if it's not pending at all (already
  /// synced) or if the retry succeeded.
  Future<bool> retryPost(String postId) async {
    var index = _feedPosts.indexWhere((p) => p.id == postId);
    final isConfession = index == -1;
    if (isConfession) {
      index = _confessions.indexWhere((p) => p.id == postId);
    }
    if (index == -1) return false;

    final post = isConfession ? _confessions[index] : _feedPosts[index];
    if (!post.isPending) return true;
    return _syncPendingPost(post, isConfession: isConfession);
  }

  /// Sets (not flips) whether [userId] likes [postId].
  ///
  /// Works for posts in the feed, in confessions, or neither (e.g. the posts
  /// on a profile page, which PostCard tracks itself). The change is shown
  /// instantly, sent to Supabase as an idempotent upsert/delete, and then the
  /// post's real count is read back so every user sees the same number.
  Future<LikeResult> setLike(String postId, String userId, bool liked) async {
    _likeInFlight.add(postId);
    _applyLocalLike(postId, liked);
    notifyListeners();

    try {
      await _postService.setLike(postId, userId, liked);
    } catch (e) {
      print('[FeedProvider] setLike error: $e');
      _applyLocalLike(postId, !liked);
      _likeInFlight.remove(postId);
      notifyListeners();
      return const LikeResult(success: false);
    }

    int? serverCount;
    try {
      final stats = await _postService.fetchEngagement([postId]);
      serverCount = stats[postId]?['like_count'];
      if (serverCount != null) _setLikeCount(postId, serverCount);
    } catch (_) {
      // The like itself succeeded; the count will be refreshed next sync.
    }

    _likeInFlight.remove(postId);
    notifyListeners();
    unawaited(_cache.saveCachedFeed(_feedPosts));
    unawaited(_cache.saveCachedConfessions(_confessions));
    return LikeResult(success: true, serverLikeCount: serverCount);
  }

  /// Optimistic local update, idempotent: asking for the state a post is
  /// already in changes nothing (no double counting).
  void _applyLocalLike(String postId, bool liked) {
    for (final list in [_feedPosts, _confessions]) {
      final i = list.indexWhere((p) => p.id == postId);
      if (i == -1) continue;
      final post = list[i];
      if (post.likedByMe == liked) continue;
      final next = post.likeCount + (liked ? 1 : -1);
      list[i] = post.copyWith(likedByMe: liked, likeCount: next < 0 ? 0 : next);
    }
  }

  void _setLikeCount(String postId, int count) {
    for (final list in [_feedPosts, _confessions]) {
      final i = list.indexWhere((p) => p.id == postId);
      if (i == -1) continue;
      list[i] = list[i].copyWith(likeCount: count);
    }
  }

  Future<void> deletePost(String postId) async {
    _feedPosts.removeWhere((p) => p.id == postId);
    _confessions.removeWhere((p) => p.id == postId);
    notifyListeners();
    unawaited(_cache.saveCachedFeed(_feedPosts));
    unawaited(_cache.saveCachedConfessions(_confessions));
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      print('[FeedProvider] deletePost error: $e');
    }
  }

  /// Cache-first comments: returns the cached list instantly (including
  /// any still-pending comments), then refreshes from Supabase in the
  /// background and retries any pending comments it finds.
  Future<List<CommentModel>> getComments(String postId) async {
    final cached = await _cache.loadCachedComments(postId);
    unawaited(_refreshComments(postId));
    if (cached.isNotEmpty) return cached;

    try {
      final fresh = await _postService.fetchComments(postId);
      await _cache.saveCachedComments(postId, fresh);
      return fresh;
    } catch (e) {
      print('[FeedProvider] getComments error: $e');
      return [];
    }
  }

  Future<void> _refreshComments(String postId) async {
    try {
      final fresh = await _postService.fetchComments(postId);
      final cached = await _cache.loadCachedComments(postId);
      final pending = cached.where((c) => c.isPending).toList();
      final merged = [...fresh, ...pending];
      await _cache.saveCachedComments(postId, merged);
      for (final p in pending) {
        unawaited(_syncPendingComment(p));
      }
    } catch (e) {
      // Offline or server error - just keep what's already cached.
    }
  }

  /// Local-first comment: appears instantly in the cache (and returns
  /// immediately) before the network call starts, exactly like [createPost].
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String content,
    ProfileModel? authorProfile,
    // Already uploaded (the comment box uploads first, then calls this).
    AttachmentInfo? attachment,
  }) async {
    final tempId = 'local-${_uuid.v4()}';
    final now = DateTime.now().toUtc().toIso8601String();

    final pendingComment = CommentModel(
      id: tempId,
      postId: postId,
      authorId: authorId,
      content: content,
      createdAt: now,
      author: authorProfile,
      attachment: attachment,
      isPending: true,
    );

    final cached = await _cache.loadCachedComments(postId);
    cached.add(pendingComment);
    await _cache.saveCachedComments(postId, cached);

    for (final list in [_feedPosts, _confessions]) {
      final index = list.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = list[index];
        list[index] = p.copyWith(commentCount: p.commentCount + 1);
        notifyListeners();
        unawaited(_cache.saveCachedFeed(_feedPosts));
        unawaited(_cache.saveCachedConfessions(_confessions));
      }
    }

    unawaited(_syncPendingComment(pendingComment));

    return pendingComment;
  }

  Future<bool> _syncPendingComment(CommentModel pendingComment) async {
    try {
      final serverComment = await _postService.addComment(
        postId: pendingComment.postId,
        authorId: pendingComment.authorId,
        content: pendingComment.content,
        attachment: pendingComment.attachment,
      );

      final cached = await _cache.loadCachedComments(pendingComment.postId);
      final idx = cached.indexWhere((c) => c.id == pendingComment.id);
      if (idx != -1) {
        cached[idx] = serverComment;
      } else {
        cached.add(serverComment);
      }
      await _cache.saveCachedComments(pendingComment.postId, cached);
      return true;
    } catch (e) {
      print('[FeedProvider] Failed to sync pending comment ${pendingComment.id}: $e');
      return false;
    }
  }

  /// Manual "tap to retry" for a single stuck comment.
  Future<bool> retryComment(String postId, String commentId) async {
    final cached = await _cache.loadCachedComments(postId);
    final idx = cached.indexWhere((c) => c.id == commentId);
    if (idx == -1) return false;
    if (!cached[idx].isPending) return true;
    return _syncPendingComment(cached[idx]);
  }
}

// Small local helper so fire-and-forget cache writes read clearly as
// intentional rather than looking like an accidentally-unawaited call.
void unawaited(Future<void> future) {}
