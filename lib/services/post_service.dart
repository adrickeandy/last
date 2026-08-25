import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/sync/sync_queue_service.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'supabase_service.dart';

class PostService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<PostModel>> fetchFeed({
    int page = 0,
    int pageSize = 15,
    String? currentUserId,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final data = await _client
        .from('posts')
        .select('*, profiles!posts_author_id_fkey(id, username, full_name, avatar_url, is_verified)')
        .eq('is_confession', false)
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();

    if (currentUserId != null && posts.isNotEmpty) {
      final postIds = posts.map((p) => p.id).toList();
      final likedIds = await fetchMyLikedPostIds(currentUserId, postIds);
      return posts.map((p) => p.copyWith(likedByMe: likedIds.contains(p.id))).toList();
    }

    return posts;
  }

  Future<List<PostModel>> fetchConfessions({
    int page = 0,
    int pageSize = 15,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final data = await _client
        .from('posts')
        .select('*')
        .eq('is_confession', true)
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<PostModel>> fetchUserPosts(String authorId, {String? currentUserId}) async {
    final data = await _client
        .from('posts')
        .select('*, profiles!posts_author_id_fkey(id, username, full_name, avatar_url, is_verified)')
        .eq('author_id', authorId)
        .order('created_at', ascending: false);

    final posts = (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();

    if (currentUserId != null && posts.isNotEmpty) {
      final postIds = posts.map((p) => p.id).toList();
      final likedIds = await fetchMyLikedPostIds(currentUserId, postIds);
      return posts.map((p) => p.copyWith(likedByMe: likedIds.contains(p.id))).toList();
    }

    return posts;
  }

  /// WhatsApp-style delta sync: fetches only posts newer than [since]
  /// instead of re-downloading the whole feed. Callers should pass the
  /// `createdAt` of the newest post they already have locally.
  Future<List<PostModel>> fetchFeedSince({
    required String since,
    String? currentUserId,
    int limit = 100,
  }) async {
    final data = await _client
        .from('posts')
        .select('*, profiles!posts_author_id_fkey(id, username, full_name, avatar_url, is_verified)')
        .eq('is_confession', false)
        .gt('created_at', since)
        .order('created_at', ascending: false)
        .limit(limit);

    final posts = (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();

    if (currentUserId != null && posts.isNotEmpty) {
      final postIds = posts.map((p) => p.id).toList();
      final likedIds = await fetchMyLikedPostIds(currentUserId, postIds);
      return posts.map((p) => p.copyWith(likedByMe: likedIds.contains(p.id))).toList();
    }

    return posts;
  }

  /// Same delta-sync principle for confessions.
  Future<List<PostModel>> fetchConfessionsSince({
    required String since,
    int limit = 100,
  }) async {
    final data = await _client
        .from('posts')
        .select('*')
        .eq('is_confession', true)
        .gt('created_at', since)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PostModel> createPost({
    required String authorId,
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    bool isConfession = false,
    String? clubId,
  }) async {
    final data = await _client
        .from('posts')
        .insert({
          'author_id': authorId,
          'content': content,
          'image_urls': imageUrls,
          'video_url': videoUrl,
          'is_confession': isConfession,
          'club_id': clubId,
        })
        .select('*, profiles!posts_author_id_fkey(id, username, full_name, avatar_url, is_verified)')
        .single();

    return PostModel.fromJson(data);
  }

  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    if (isLiked) {
      await _client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _client.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  Future<Set<String>> fetchMyLikedPostIds(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return {};

    final data = await _client
        .from('likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);

    return (data as List).map((r) => r['post_id'] as String).toSet();
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final data = await _client
        .from('comments')
        .select('*, profiles!comments_author_id_fkey(id, username, full_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (data as List).map((json) => CommentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    final data = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'author_id': authorId,
          'content': content,
        })
        .select('*, profiles!comments_author_id_fkey(id, username, full_name, avatar_url)')
        .single();

    return CommentModel.fromJson(data);
  }

  // ---------------------------------------------------------------------
  // Offline-first additions below. Nothing above this line was changed -
  // existing callers of createPost/addComment behave exactly as before.
  // ---------------------------------------------------------------------

  /// Builds a local-only, instantly-displayable PostModel (isPending: true)
  /// and queues the real write for SyncQueueService to replay when online.
  ///
  /// NOTE ON IMAGES: this deliberately does NOT put [localImagePaths] into
  /// the returned PostModel.imageUrls - that field is rendered elsewhere
  /// (presumably with CachedNetworkImage in post_card.dart) and a local
  /// file path would break that widget. Until I've seen post_card.dart,
  /// treat pending-post images as a follow-up: the queue item still carries
  /// localImagePaths so the sync handler can upload them once we wire it,
  /// but the UI needs its own "show local file for pending posts" branch.
  PostModel buildPendingPost({
    required String authorId,
    required String content,
    List<String> localImagePaths = const [],
    bool isConfession = false,
    String? clubId,
  }) {
    final localId = SyncQueueService.instance.newLocalId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final pendingPost = PostModel(
      id: localId,
      authorId: authorId,
      content: content,
      videoUrl: null,
      isConfession: isConfession,
      clubId: clubId,
      createdAt: nowIso,
      updatedAt: nowIso,
      isPending: true,
    );

    SyncQueueService.instance.enqueue(
      id: localId,
      entityType: 'post',
      opType: 'create',
      payload: {
        'author_id': authorId,
        'content': content,
        'is_confession': isConfession,
        'club_id': clubId,
      },
      localImagePaths: localImagePaths,
    );

    return pendingPost;
  }

  /// Same idea for comments - instant local CommentModel, queued write.
  CommentModel buildPendingComment({
    required String postId,
    required String authorId,
    required String content,
  }) {
    final localId = SyncQueueService.instance.newLocalId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final pendingComment = CommentModel(
      id: localId,
      postId: postId,
      authorId: authorId,
      content: content,
      createdAt: nowIso,
      isPending: true,
    );

    SyncQueueService.instance.enqueue(
      id: localId,
      entityType: 'comment',
      opType: 'create',
      payload: {
        'post_id': postId,
        'author_id': authorId,
        'content': content,
      },
    );

    return pendingComment;
  }
}
