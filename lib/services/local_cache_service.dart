import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';

/// Local-first cache for feed data, comments, and messages.
///
/// Deliberately built on `shared_preferences` (already a project dependency)
/// rather than adding a new local-database package — this project has been
/// burned before by native-plugin dependencies breaking the Windows build
/// (app_links), so a pure-Dart, already-proven storage path is the safer
/// default for a cache of this size (a bounded list of recent posts,
/// comments, and messages).
///
/// If the cached data ever needs to grow much larger, or needs real
/// querying (e.g. full-text search over cached posts), migrate this to
/// `sqflite_common_ffi` (desktop) / `sqflite` (mobile) or `hive` — but
/// that's a deliberate future upgrade, not needed today.
class LocalCacheService {
  static const _feedKey = 'cache_feed_posts_v1';
  static const _confessionsKey = 'cache_confessions_posts_v1';
  static const _commentsPrefix = 'cache_comments_v1_';
  static const _messagesPrefix = 'cache_messages_v1_';

  // Cap how many items we persist locally per key so the cache can't grow
  // unbounded on an account that's been active for a long time.
  static const _maxCachedPosts = 300;
  static const _maxCachedComments = 200;
  static const _maxCachedMessages = 500;

  Future<List<PostModel>> loadCachedFeed() => _loadPosts(_feedKey);
  Future<void> saveCachedFeed(List<PostModel> posts) => _savePosts(_feedKey, posts);

  Future<List<PostModel>> loadCachedConfessions() => _loadPosts(_confessionsKey);
  Future<void> saveCachedConfessions(List<PostModel> posts) => _savePosts(_confessionsKey, posts);

  /// Comments for one post, oldest-first (matches PostService.fetchComments'
  /// ordering), so CommentSectionWidget can render the list as-is.
  Future<List<CommentModel>> loadCachedComments(String postId) =>
      _loadComments('$_commentsPrefix$postId');
  Future<void> saveCachedComments(String postId, List<CommentModel> comments) =>
      _saveComments('$_commentsPrefix$postId', comments);

  /// Messages for one conversation, oldest-first (matches
  /// MessageService.fetchMessages' ordering).
  Future<List<MessageModel>> loadCachedMessages(String conversationId) =>
      _loadMessages('$_messagesPrefix$conversationId');
  Future<void> saveCachedMessages(String conversationId, List<MessageModel> messages) =>
      _saveMessages('$_messagesPrefix$conversationId', messages);

  Future<List<PostModel>> _loadPosts(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => PostModel.fromCachedJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // A corrupted/old-shape cache entry should never crash the feed —
      // just treat it as "no cache" and let a normal network fetch repopulate it.
      print('[LocalCacheService] Failed to load cache for $key: $e');
      return [];
    }
  }

  Future<void> _savePosts(String key, List<PostModel> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bounded = posts.length > _maxCachedPosts
          ? posts.sublist(0, _maxCachedPosts)
          : posts;
      final encoded = jsonEncode(bounded.map((p) => p.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      // Caching is a best-effort optimization — never let a write failure
      // (e.g. disk full) interrupt the feed itself.
      print('[LocalCacheService] Failed to save cache for $key: $e');
    }
  }

  Future<List<CommentModel>> _loadComments(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => CommentModel.fromCachedJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[LocalCacheService] Failed to load comments for $key: $e');
      return [];
    }
  }

  Future<void> _saveComments(String key, List<CommentModel> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep the most recent ones if we're over the cap - comments are
      // stored oldest-first, so trim from the front.
      final bounded = comments.length > _maxCachedComments
          ? comments.sublist(comments.length - _maxCachedComments)
          : comments;
      final encoded = jsonEncode(bounded.map((c) => c.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      print('[LocalCacheService] Failed to save comments for $key: $e');
    }
  }

  Future<List<MessageModel>> _loadMessages(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => MessageModel.fromCachedJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[LocalCacheService] Failed to load messages for $key: $e');
      return [];
    }
  }

  Future<void> _saveMessages(String key, List<MessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bounded = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;
      final encoded = jsonEncode(bounded.map((m) => m.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      print('[LocalCacheService] Failed to save messages for $key: $e');
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (k) =>
              k == _feedKey ||
              k == _confessionsKey ||
              k.startsWith(_commentsPrefix) ||
              k.startsWith(_messagesPrefix),
        );
    for (final k in keys.toList()) {
      await prefs.remove(k);
    }
  }
}
