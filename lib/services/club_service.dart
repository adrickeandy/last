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

    // Create the club's group conversation first. Its id gets stored on
    // the club row so the UI has something to open when a member taps
    // "Group chat".
    final convData = await _client
        .from('conversations')
        .insert({
          'is_group': true,
          'title': name,
          'created_by': createdBy,
        })
        .select()
        .single();
    final conversationId = convData['id'] as String;

    // Creator must be a conversation_members row immediately, same reason
    // as the direct-message fix: the conversations SELECT policy checks
    // membership (or created_by), and would otherwise show 0 rows for
    // everyone else who joins before the creator is added.
    await _client.from('conversation_members').insert({
      'conversation_id': conversationId,
      'user_id': createdBy,
    });

    final data = await _client
        .from('clubs')
        .insert({
          'name': name,
          'slug': slug,
          'description': description,
          'created_by': createdBy,
          'conversation_id': conversationId,
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

  /// [conversationId] should be the club's conversationId (from ClubModel),
  /// so the joining user is also added as a member of the club's group
  /// chat, not just the club roster. Pass null only for clubs that predate
  /// this feature and have no linked conversation yet.
  Future<void> joinClub(String clubId, String userId, {String? conversationId}) async {
    await _client.from('club_members').insert({
      'club_id': clubId,
      'user_id': userId,
    });

    if (conversationId != null) {
      await _client.from('conversation_members').insert({
        'conversation_id': conversationId,
        'user_id': userId,
      });
    }
  }

  Future<void> leaveClub(String clubId, String userId, {String? conversationId}) async {
    await _client
        .from('club_members')
        .delete()
        .eq('club_id', clubId)
        .eq('user_id', userId);

    if (conversationId != null) {
      await _client
          .from('conversation_members')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    }
  }

  Future<int> fetchClubMemberCount(String clubId) async {
    // NOTE: was previously select('id') -- club_members has no `id` column
    // (composite key of club_id/user_id), which threw a Postgres "column
    // does not exist" error on every call. Same class of bug as the earlier
    // follows-table fix.
    final res = await _client
        .from('club_members')
        .select('user_id')
        .eq('club_id', clubId)
        .count(CountOption.exact);
    return res.count ?? 0;
  }
}
