import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_model.dart';
import 'supabase_service.dart';

class ClubService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<ClubModel>> fetchClubs({String? currentUserId}) async {
    final data = await _client
        .from('clubs')
        .select('*')
        .order('created_at', ascending: false);

    final clubs = (data as List).map((json) => ClubModel.fromJson(json as Map<String, dynamic>)).toList();

    if (currentUserId != null && clubs.isNotEmpty) {
      final clubIds = clubs.map((c) => c.id).toList();
      final myMemberships = await _client
          .from('club_members')
          .select('club_id')
          .eq('user_id', currentUserId)
          .inFilter('club_id', clubIds);

      final joinedSet = (myMemberships as List).map((m) => m['club_id'] as String).toSet();

      return clubs.map((c) => c.copyWith(isMember: joinedSet.contains(c.id))).toList();
    }

    return clubs;
  }

  Future<ClubModel> createClub({
    required String name,
    required String description,
    required String createdBy,
  }) async {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'(^-|-$)'), '');

    final data = await _client
        .from('clubs')
        .insert({
          'name': name,
          'slug': slug,
          'description': description,
          'created_by': createdBy,
        })
        .select()
        .single();

    // Auto add creator as owner
    await _client.from('club_members').insert({
      'club_id': data['id'],
      'user_id': createdBy,
      'role': 'owner',
    });

    return ClubModel.fromJson(data, isMember: true);
  }

  Future<void> joinClub(String clubId, String userId) async {
    await _client.from('club_members').insert({
      'club_id': clubId,
      'user_id': userId,
    });
  }

  Future<void> leaveClub(String clubId, String userId) async {
    await _client
        .from('club_members')
        .delete()
        .eq('club_id', clubId)
        .eq('user_id', userId);
  }

  Future<int> fetchClubMemberCount(String clubId) async {
    final res = await _client
        .from('club_members')
        .select('id')
        .eq('club_id', clubId)
        .count(CountOption.exact);

    return res.count ?? 0;
  }
}
