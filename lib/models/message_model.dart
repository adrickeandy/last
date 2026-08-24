import 'profile_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<String> readBy;
  final String createdAt;
  final ProfileModel? sender;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.readBy = const [],
    required this.createdAt,
    this.sender,
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
}
