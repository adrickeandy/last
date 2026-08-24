enum AiRole {
  user,
  assistant,
}

class AiMessageModel {
  final String id;
  final String userId;
  final AiRole role;
  final String content;
  final String createdAt;

  AiMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'user';
    return AiMessageModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: roleStr == 'assistant' ? AiRole.assistant : AiRole.user,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  AiMessageModel copyWith({String? content}) {
    return AiMessageModel(
      id: id,
      userId: userId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role == AiRole.assistant ? 'assistant' : 'user',
      'content': content,
    };
  }
}
