import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/local_cache_service.dart';

/// Chat state, offline-first - same approach as FeedProvider:
///
/// - Opening a conversation shows its cached messages immediately, then
///   refreshes from Supabase in the background (there's no delta-fetch
///   endpoint for messages yet, so this is a full re-fetch merged with
///   whatever's still pending locally).
/// - Sending a message writes it to the cache and shows it instantly,
///   before the network call starts, and retries automatically on the
///   next time that conversation is opened - plus a manual [retryMessage]
///   for a "tap to retry" button.
class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final LocalCacheService _cache = LocalCacheService();
  final _uuid = const Uuid();

  List<ConversationModel> _conversations = [];
  String? _activeConversationId;
  List<MessageModel> _activeMessages = [];
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  RealtimeChannel? _subscription;

  List<ConversationModel> get conversations => _conversations;
  String? get activeConversationId => _activeConversationId;
  List<MessageModel> get activeMessages => _activeMessages;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;

  ConversationModel? get activeConversation {
    if (_activeConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeConversationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadConversations(String userId) async {
    _isLoadingConversations = true;
    notifyListeners();
    try {
      _conversations = await _messageService.fetchConversations(userId);
    } catch (e) {
      print('[ChatProvider] loadConversations error: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(String conversationId) async {
    if (_activeConversationId == conversationId) return;
    _activeConversationId = conversationId;
    _activeMessages = [];
    _isLoadingMessages = true;
    notifyListeners();

    // Clean up previous subscription
    if (_subscription != null) {
      await _messageService.unsubscribe(_subscription!);
      _subscription = null;
    }

    // Cache-first hydrate: shows the last-known thread instantly, even
    // fully offline.
    final cached = await _cache.loadCachedMessages(conversationId);
    if (cached.isNotEmpty) {
      _activeMessages = cached;
      _isLoadingMessages = false;
      notifyListeners();
    }

    try {
      final fresh = await _messageService.fetchMessages(conversationId);
      final pending = _activeMessages.where((m) => m.isPending).toList();
      final freshIds = fresh.map((m) => m.id).toSet();
      final merged = [...fresh, ...pending.where((p) => !freshIds.contains(p.id))]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _activeMessages = merged;
      await _cache.saveCachedMessages(conversationId, _activeMessages);

      // Resend anything that was sent offline and never reached the server.
      for (final p in pending) {
        unawaited(_syncPendingMessage(p));
      }
    } catch (e) {
      print('[ChatProvider] fetchMessages error: $e');
      // Keep whatever cache we already showed - conversation just stays
      // possibly-stale rather than going blank.
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }

    // Subscribe to realtime changes for active conversation
    _subscription = _messageService.subscribeToMessages(conversationId, (newMsg) {
      if (!_activeMessages.any((m) => m.id == newMsg.id)) {
        _activeMessages.add(newMsg);
        notifyListeners();
        unawaited(_cache.saveCachedMessages(conversationId, _activeMessages));
      }
    });
  }

  /// Local-first send: the bubble appears instantly (and survives an app
  /// restart via the cache) before the network call even starts. If it
  /// fails - e.g. no connection - the message stays in the thread marked
  /// pending, resent automatically next time this conversation is opened,
  /// or manually via [retryMessage].
  Future<void> sendMessage({
    required String senderId,
    required String content,
  }) async {
    if (_activeConversationId == null || content.trim().isEmpty) return;
    final conversationId = _activeConversationId!;
    final tempId = 'local-${_uuid.v4()}';
    final now = DateTime.now().toUtc().toIso8601String();

    final pendingMessage = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: senderId,
      content: content.trim(),
      createdAt: now,
      isPending: true,
    );

    _activeMessages.add(pendingMessage);
    notifyListeners();
    unawaited(_cache.saveCachedMessages(conversationId, _activeMessages));

    await _syncPendingMessage(pendingMessage);
  }

  /// Attempts to push a single pending message to Supabase, replacing it
  /// in place with the server-confirmed version on success. Handles the
  /// case where the user has since switched to a different conversation -
  /// in that case it patches that conversation's cache directly instead of
  /// touching the (now unrelated) active message list.
  Future<bool> _syncPendingMessage(MessageModel pendingMessage) async {
    try {
      final serverMsg = await _messageService.sendMessage(
        conversationId: pendingMessage.conversationId,
        senderId: pendingMessage.senderId,
        content: pendingMessage.content,
      );

      if (pendingMessage.conversationId == _activeConversationId) {
        final index = _activeMessages.indexWhere((m) => m.id == pendingMessage.id);
        if (index != -1) {
          _activeMessages[index] = serverMsg;
        }
        notifyListeners();
        unawaited(_cache.saveCachedMessages(pendingMessage.conversationId, _activeMessages));
      } else {
        final cached = await _cache.loadCachedMessages(pendingMessage.conversationId);
        final idx = cached.indexWhere((m) => m.id == pendingMessage.id);
        if (idx != -1) cached[idx] = serverMsg;
        await _cache.saveCachedMessages(pendingMessage.conversationId, cached);
      }
      return true;
    } catch (e) {
      print('[ChatProvider] Failed to sync pending message ${pendingMessage.id}: $e');
      return false;
    }
  }

  /// Manual "tap to retry" for a single stuck message - wire this to a
  /// retry icon in MessageBubble. Only works for the currently active
  /// conversation's messages (which is all a retry tap in the UI can be
  /// for, since you can only tap a bubble you're looking at).
  Future<bool> retryMessage(String messageId) async {
    final index = _activeMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;
    final message = _activeMessages[index];
    if (!message.isPending) return true;
    return _syncPendingMessage(message);
  }

  Future<String> startOrGetDirectChat(String myUserId, String otherUserId) async {
    final convId = await _messageService.findOrCreateDirectConversation(myUserId, otherUserId);
    await loadConversations(myUserId);
    await selectConversation(convId);
    return convId;
  }

  @override
  void dispose() {
    if (_subscription != null) {
      _messageService.unsubscribe(_subscription!);
    }
    super.dispose();
  }
}

// Small local helper so fire-and-forget cache writes read clearly as
// intentional rather than looking like an accidentally-unawaited call.
void unawaited(Future<void> future) {}
