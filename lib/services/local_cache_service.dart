import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

/// Local-first cache for feed data.
///
/// Deliberately built on `shared_preferences` (already a project dependency)
/// rather than adding a new local-database package — this project has been
/// burned before by native-plugin dependencies breaking the Windows build
/// (app_links), so a pure-Dart, already-proven storage path is the safer
/// default for a cache of this size (a bounded list of recent posts).
///
/// If the cached feed ever needs to grow much larger than a few hundred
/// posts, or needs real querying (e.g. full-text search over cached posts),
/// migrate this to `sqflite_common_ffi` (desktop) / `sqflite` (mobile) or
/// `hive` — but that's a deliberate future upgrade, not needed today.
class LocalCacheService {
  static const _feedKey = 'cache_feed_posts_v1';
  static const _confessionsKey = 'cache_confessions_posts_v1';
  // Cap how many posts we persist locally so the cache can't grow
  // unbounded on an account that's been active for a long time.
  static const _maxCachedPosts = 300;

  Future<List<PostModel>> loadCachedFeed() => _loadPosts(_feedKey);
  Future<void> saveCachedFeed(List<PostModel> posts) => _savePosts(_feedKey, posts);

  Future<List<PostModel>> loadCachedConfessions() => _loadPosts(_confessionsKey);
  Future<void> saveCachedConfessions(List<PostModel> posts) => _savePosts(_confessionsKey, posts);

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

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedKey);
    await prefs.remove(_confessionsKey);
  }
}
