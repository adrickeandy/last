import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/profile_model.dart';
import '../services/post_service.dart';
import '../services/local_cache_service.dart';

/// Feed state, built offline-first ("WhatsApp method"):
///
/// - On load, cached posts render immediately (instant, works offline).
/// - Refreshing (pull-to-refresh or coming back online) fetches only posts
///   newer than the newest one already held — never the whole table again.
/// - New posts are written to the local cache immediately, before the
///   network call even starts, and are retried automatically if that
///   network call fails while offline.
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

  List<PostModel> get feedPosts => _feedPosts;
  List<PostModel> get confessions => _confessions;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingConfessions => _isLoadingConfessions;
  bool get isPosting => _isPosting;
  bool get isSyncing => _isSyncing;
  bool get isOffline => _isOffline;

  Future<void> loadFeed(String? userId) async {
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

  Future<void> loadConfessions() async {
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
  /// [loadFeed] call.
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

  Future<void> toggleLike(String postId, String userId) async {
    final index = _feedPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _feedPosts[index];
    final nextLiked = !post.likedByMe;
    final nextCount = post.likeCount + (nextLiked ? 1 : -1);

    _feedPosts[index] = post.copyWith(
      likedByMe: nextLiked,
      likeCount: nextCount < 0 ? 0 : nextCount,
    );
    notifyListeners();
    unawaited(_cache.saveCachedFeed(_feedPosts));

    try {
      await _postService.toggleLike(postId, userId, post.likedByMe);
    } catch (e) {
      // Revert on error
      _feedPosts[index] = post;
      notifyListeners();
      unawaited(_cache.saveCachedFeed(_feedPosts));
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

  Future<List<CommentModel>> getComments(String postId) async {
    return await _postService.fetchComments(postId);
  }

  Future<CommentModel?> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    try {
      final comment = await _postService.addComment(
        postId: postId,
        authorId: authorId,
        content: content,
      );

      final index = _feedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = _feedPosts[index];
        _feedPosts[index] = p.copyWith(commentCount: p.commentCount + 1);
        notifyListeners();
        unawaited(_cache.saveCachedFeed(_feedPosts));
      }

      return comment;
    } catch (e) {
      print('[FeedProvider] addComment error: $e');
      return null;
    }
  }
}

// Small local helper so fire-and-forget cache writes read clearly as
// intentional rather than looking like an accidentally-unawaited call.
void unawaited(Future<void> future) {}
