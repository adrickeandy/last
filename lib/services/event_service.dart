import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import 'supabase_service.dart';

class EventService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<EventModel>> fetchUpcomingEvents({String? currentUserId}) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('events')
        .select('*')
        .gte('starts_at', nowIso)
        .order('starts_at', ascending: true);

    final events = (data as List).map((json) => EventModel.fromJson(json as Map<String, dynamic>)).toList();

    if (currentUserId != null && events.isNotEmpty) {
      final eventIds = events.map((e) => e.id).toList();
      final myRsvps = await _client
          .from('event_rsvps')
          .select('event_id')
          .eq('user_id', currentUserId)
          .eq('status', 'going')
          .inFilter('event_id', eventIds);

      final goingSet = (myRsvps as List).map((r) => r['event_id'] as String).toSet();

      return events.map((e) => e.copyWith(isGoing: goingSet.contains(e.id))).toList();
    }

    return events;
  }

  Future<EventModel> createEvent({
    required String hostId,
    required String title,
    required String description,
    required String location,
    required String startsAt,
    String? clubId,
  }) async {
    final data = await _client
        .from('events')
        .insert({
          'host_id': hostId,
          'title': title,
          'description': description,
          'location': location,
          'starts_at': startsAt,
          'club_id': clubId,
        })
        .select()
        .single();

    return EventModel.fromJson(data);
  }

  Future<void> rsvpToEvent({
    required String eventId,
    required String userId,
    String status = 'going',
  }) async {
    await _client.from('event_rsvps').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': status,
    }, onConflict: 'event_id,user_id');
  }

  Future<int> fetchRsvpCount(String eventId) async {
    final res = await _client
        .from('event_rsvps')
        .select('id')
        .eq('event_id', eventId)
        .eq('status', 'going')
        .count(CountOption.exact);

    return res.count ?? 0;
  }
}
