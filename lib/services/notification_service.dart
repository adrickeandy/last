import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select('*, profiles!notifications_actor_id_fkey(id, username, avatar_url)')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', userId)
        .eq('is_read', false);
  }

  RealtimeChannel subscribeToNotifications(String userId, Function(NotificationModel) onNewNotification) {
    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) {
            onNewNotification(NotificationModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
