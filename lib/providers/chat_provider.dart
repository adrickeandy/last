import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

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

    try {
      _activeMessages = await _messageService.fetchMessages(conversationId);
    } catch (e) {
      print('[ChatProvider] fetchMessages error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }

    // Subscribe to realtime changes for active conversation
    _subscription = _messageService.subscribeToMessages(conversationId, (newMsg) {
      if (!_activeMessages.any((m) => m.id == newMsg.id)) {
        _activeMessages.add(newMsg);
        notifyListeners();
      }
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String content,
  }) async {
    if (_activeConversationId == null || content.trim().isEmpty) return;

    try {
      final msg = await _messageService.sendMessage(
        conversationId: _activeConversationId!,
        senderId: senderId,
        content: content.trim(),
      );

      if (!_activeMessages.any((m) => m.id == msg.id)) {
        _activeMessages.add(msg);
        notifyListeners();
      }
    } catch (e) {
      print('[ChatProvider] sendMessage error: $e');
    }
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
