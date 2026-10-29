import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poll_model.dart';
import 'supabase_service.dart';

class PollService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<PollModel>> fetchPolls({String? currentUserId}) async {
    final data = await _client
        .from('polls')
        .select('*')
        .order('created_at', ascending: false);

    final polls = (data as List).map((json) => PollModel.fromJson(json as Map<String, dynamic>)).toList();

    final List<PollModel> enrichedPolls = [];
    for (final poll in polls) {
      final results = await fetchPollResults(poll.id);
      int? myVote;
      if (currentUserId != null) {
        final voteData = await _client
            .from('poll_votes')
            .select('option_index')
            .eq('poll_id', poll.id)
            .eq('user_id', currentUserId)
            .maybeSingle();
        if (voteData != null) {
          myVote = voteData['option_index'] as int?;
        }
      }
      enrichedPolls.add(poll.copyWith(voteResults: results, myVoteIndex: myVote));
    }

    return enrichedPolls;
  }

  Future<Map<int, int>> fetchPollResults(String pollId) async {
    final data = await _client
        .from('poll_votes')
        .select('option_index')
        .eq('poll_id', pollId);

    final Map<int, int> counts = {};
    for (final row in (data as List)) {
      final idx = row['option_index'] as int;
      counts[idx] = (counts[idx] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> castVote({
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    await _client.from('poll_votes').upsert({
      'poll_id': pollId,
      'user_id': userId,
      'option_index': optionIndex,
    }, onConflict: 'poll_id,user_id');
  }

  Future<PollModel> createPoll({
    required String authorId,
    required String question,
    required List<String> options,
  }) async {
    final data = await _client
        .from('polls')
        .insert({
          'author_id': authorId,
          'question': question,
          'options': options,
        })
        .select()
        .single();

    return PollModel.fromJson(data);
  }
}
