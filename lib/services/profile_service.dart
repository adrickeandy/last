import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseService.client;

  Future<ProfileModel?> fetchProfileByUsername(String username) async {
    final data = await _client
        .from('profiles')
        .select('*')
        .eq('username', username)
        .maybeSingle();

    if (data != null) {
      return ProfileModel.fromJson(data);
    }
    return null;
  }

  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<List<ProfileModel>> searchProfiles(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final data = await _client
        .from('profiles')
        .select('*')
        .or('username.ilike.%$cleanQuery%,full_name.ilike.%$cleanQuery%')
        .limit(25);

    return (data as List).map((json) => ProfileModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> followUser(String followerId, String followingId) async {
    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final data = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();

    return data != null;
  }

  Future<Map<String, int>> fetchFollowCounts(String userId) async {
    final followersRes = await _client
        .from('follows')
        .select('id')
        .eq('following_id', userId)
        .count(CountOption.exact);

    final followingRes = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', userId)
        .count(CountOption.exact);

    return {
      'followers': followersRes.count ?? 0,
      'following': followingRes.count ?? 0,
    };
  }
}
