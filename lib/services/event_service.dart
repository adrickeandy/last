import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event_model.dart';
import 'supabase_service.dart';

class EventService {
  final SupabaseClient _client = SupabaseService.client;

  // Mirrors MarketplaceService's _imageBucket pattern. Requires a public
  // Supabase Storage bucket named 'event-images' - same setup as the
  // existing 'marketplace-images' bucket, just not created by this code.
  static const String _coverImageBucket = 'event-images';

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

  /// Uploads a single event cover image to Supabase Storage and returns
  /// its public URL. Same mechanics as
  /// MarketplaceService.uploadMarketplaceImages, just for one file instead
  /// of a list.
  Future<String> uploadEventCoverImage({
    required String hostId,
    required XFile image,
  }) async {
    final Uint8List bytes = await image.readAsBytes();
    final extension = _getExtension(image.name);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final storagePath = '$hostId/$fileName';

    await _client.storage.from(_coverImageBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
            upsert: false,
          ),
        );

    return _client.storage.from(_coverImageBucket).getPublicUrl(storagePath);
  }

  Future<EventModel> createEvent({
    required String hostId,
    required String title,
    required String description,
    required String location,
    required String startsAt,
    String? clubId,
    String? coverUrl,
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
          'cover_url': coverUrl,
        })
        .select()
        .single();
    return EventModel.fromJson(data);
  }

  /// Convenience wrapper: uploads [coverImage] first (if provided) then
  /// creates the event with the resulting URL. Lets CreateEventDialog make
  /// one call instead of orchestrating upload-then-create itself.
  Future<EventModel> createEventWithCover({
    required String hostId,
    required String title,
    required String description,
    required String location,
    required String startsAt,
    String? clubId,
    XFile? coverImage,
  }) async {
    String? coverUrl;
    if (coverImage != null) {
      coverUrl = await uploadEventCoverImage(hostId: hostId, image: coverImage);
    }

    return createEvent(
      hostId: hostId,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      clubId: clubId,
      coverUrl: coverUrl,
    );
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

  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final extension = parts.last.toLowerCase();
    const allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'];
    if (!allowed.contains(extension)) return 'jpg';
    return extension;
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }
}
