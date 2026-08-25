import 'profile_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<String> readBy;
  final String createdAt;
  final ProfileModel? sender;
  // Same convention as PostModel.isPending: true only for messages sent
  // locally that haven't been confirmed by the server yet. Never comes from
  // Supabase itself - defaults to false so nothing existing breaks.
  final bool isPending;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.readBy = const [],
    required this.createdAt,
    this.sender,
    this.isPending = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? senderProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      senderProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }
    final rawReadBy = json['read_by'];
    List<String> readByList = [];
    if (rawReadBy is List) {
      readByList = rawReadBy.map((e) => e.toString()).toList();
    }
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      readBy: readByList,
      createdAt: json['created_at'] as String? ?? '',
      sender: senderProfile,
    );
  }

  MessageModel copyWith({
    String? content,
    List<String>? readBy,
    ProfileModel? sender,
    bool? isPending,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content ?? this.content,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt,
      sender: sender ?? this.sender,
      isPending: isPending ?? this.isPending,
    );
  }
}
