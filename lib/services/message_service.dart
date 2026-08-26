import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/sync/sync_queue_item.dart';
import '../core/sync/sync_queue_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

class MessageService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<ConversationModel>> fetchConversations(String userId) async {
    final memberships = await _client
        .from('conversation_members')
        .select(
          'conversation_id, conversations(id, is_group, title, created_at)',
        )
        .eq('user_id', userId);

    final List<String> convIds = (memberships as List)
        .map((m) => m['conversation_id'] as String)
        .toList();

    if (convIds.isEmpty) return [];

    final otherMembers = await _client
        .from('conversation_members')
        .select(
          'conversation_id, profiles(id, username, full_name, avatar_url)',
        )
        .inFilter('conversation_id', convIds)
        .neq('user_id', userId);

    final otherByConv = <String, ProfileModel?>{};

    for (final row in (otherMembers as List)) {
      final cid = row['conversation_id'] as String;

      if (!otherByConv.containsKey(cid) && row['profiles'] != null) {
        otherByConv[cid] = ProfileModel.fromJson(
          row['profiles'] as Map<String, dynamic>,
        );
      }
    }

    final List<ConversationModel> result = [];

    for (final m in memberships) {
      final cid = m['conversation_id'] as String;

      final convData = m['conversations'] as Map<String, dynamic>?;

      if (convData != null) {
        result.add(
          ConversationModel.fromJson(
            convData,
            otherProfile: otherByConv[cid],
          ),
        );
      }
    }

    return result;
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select(
          '*, profiles!messages_sender_id_fkey(id, username, full_name, avatar_url)',
        )
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map(
          (json) => MessageModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select(
          '*, profiles!messages_sender_id_fkey(id, username, full_name, avatar_url)',
        )
        .single();

    return MessageModel.fromJson(data);
  }

  /// Replays an offline queued message.
  ///
  /// This method deliberately uses the same Supabase insert/select shape as
  /// [sendMessage], so the server-confirmed MessageModel contains the sender
  /// profile as well.
  Future<MessageModel> syncQueuedMessage(
    SyncQueueItem item,
  ) async {
    if (item.entityType != 'message') {
      throw ArgumentError(
        'MessageService received unsupported entity type: ${item.entityType}',
      );
    }

    if (item.opType != 'create') {
      throw ArgumentError(
        'MessageService received unsupported message operation: ${item.opType}',
      );
    }

    final conversationId = item.payload['conversation_id']?.toString();
    final senderId = item.payload['sender_id']?.toString();
    final content = item.payload['content']?.toString();

    if (conversationId == null || conversationId.isEmpty) {
      throw ArgumentError('Queued message has no conversation_id.');
    }

    if (senderId == null || senderId.isEmpty) {
      throw ArgumentError('Queued message has no sender_id.');
    }

    if (content == null || content.trim().isEmpty) {
      throw ArgumentError('Queued message has no content.');
    }

    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select(
          '*, profiles!messages_sender_id_fkey(id, username, full_name, avatar_url)',
        )
        .single();

    return MessageModel.fromJson(data);
  }

  Future<ConversationModel> startDirectConversation(
    String userAId,
    String userBId,
  ) async {
    final convData = await _client
        .from('conversations')
        .insert({
          'is_group': false,
          'created_by': userAId,
        })
        .select()
        .single();

    final convId = convData['id'] as String;

    await _client.from('conversation_members').insert([
      {
        'conversation_id': convId,
        'user_id': userAId,
      },
      {
        'conversation_id': convId,
        'user_id': userBId,
      },
    ]);

    return ConversationModel.fromJson(convData);
  }

  Future<String> findOrCreateDirectConversation(
    String userAId,
    String userBId,
  ) async {
    final myMemberships = await _client
        .from('conversation_members')
        .select(
          'conversation_id, conversations!inner(is_group)',
        )
        .eq('user_id', userAId)
        .eq('conversations.is_group', false);

    final myConvIds = (myMemberships as List)
        .map((m) => m['conversation_id'] as String)
        .toList();

    if (myConvIds.isNotEmpty) {
      final shared = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userBId)
          .inFilter('conversation_id', myConvIds)
          .limit(1);

      if ((shared as List).isNotEmpty) {
        return shared.first['conversation_id'] as String;
      }
    }

    final conv = await startDirectConversation(
      userAId,
      userBId,
    );

    return conv.id;
  }

  RealtimeChannel subscribeToMessages(
    String conversationId,
    Function(MessageModel) onNewMessage,
  ) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;

            onNewMessage(
              MessageModel.fromJson(newRecord),
            );
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // -------------------------------------------------------------------------
  // OFFLINE-FIRST MESSAGE SUPPORT
  // -------------------------------------------------------------------------

  /// Creates the local optimistic message and places its server write into
  /// SyncQueueService.
  ///
  /// The returned MessageModel is intentionally marked isPending=true.
  /// ChatProvider displays it immediately and later replaces it with the
  /// server-confirmed message when the queue handler succeeds.
  MessageModel buildPendingMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    final localId = SyncQueueService.instance.newLocalId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final pendingMessage = MessageModel(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: nowIso,
      isPending: true,
    );

    SyncQueueService.instance.enqueue(
      id: localId,
      entityType: 'message',
      opType: 'create',
      payload: {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      },
    );

    return pendingMessage;
  }
}
