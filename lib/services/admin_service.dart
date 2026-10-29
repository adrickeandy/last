import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../models/profile_model.dart';
import '../models/post_model.dart';
import 'supabase_service.dart';

class AdminService {
  final SupabaseClient _client = SupabaseService.client;

  Future<Map<String, int>> fetchAdminStats() async {
    final results = await Future.wait([
      _client.from('profiles').select('id').count(CountOption.exact),
      _client.from('posts').select('id').count(CountOption.exact),
      _client.from('reports').select('id').eq('status', 'pending').count(CountOption.exact),
      _client.from('profiles').select('id').eq('is_banned', true).count(CountOption.exact),
      _client.from('messages').select('id').count(CountOption.exact),
    ]);

    return {
      'users': results[0].count ?? 0,
      'posts': results[1].count ?? 0,
      'openReports': results[2].count ?? 0,
      'bannedUsers': results[3].count ?? 0,
      'messages': results[4].count ?? 0,
    };
  }

  Future<List<ProfileModel>> fetchAllUsers() async {
    final data = await _client
        .from('profiles')
        .select('*')
        .order('created_at', ascending: false)
        .limit(100);

    return (data as List).map((json) => ProfileModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> toggleBanUser(String userId, bool isBanned) async {
    await _client.from('profiles').update({'is_banned': isBanned}).eq('id', userId);
  }

  Future<void> toggleVerifyUser(String userId, bool isVerified) async {
    await _client.from('profiles').update({'is_verified': isVerified}).eq('id', userId);
  }

  Future<List<PostModel>> fetchRecentPosts() async {
    final data = await _client
        .from('posts')
        .select('*, profiles!posts_author_id_fkey(id, username, full_name, avatar_url, is_verified)')
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ReportModel>> fetchReports() async {
    final data = await _client
        .from('reports')
        .select('*, profiles!reports_reporter_id_fkey(id, username, avatar_url), posts(*)')
        .order('created_at', ascending: false);

    return (data as List).map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> resolveReport(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<List<FeatureFlagModel>> fetchFeatureFlags() async {
    final data = await _client
        .from('feature_flags')
        .select('*')
        .order('key', ascending: true);

    return (data as List).map((json) => FeatureFlagModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> updateFeatureFlag(String key, bool enabled) async {
    await _client.from('feature_flags').update({
      'enabled': enabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('key', key);
  }

  Future<List<AdminLogModel>> fetchAdminLogs() async {
    final data = await _client
        .from('admin_logs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((json) => AdminLogModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
