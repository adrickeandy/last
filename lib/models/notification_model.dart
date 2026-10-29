import 'profile_model.dart';

enum NotificationType {
  like,
  comment,
  follow,
  message,
  clubInvite,
  event,
  poll,
  mention,
  unknown,
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String? actorId;
  final NotificationType type;
  final String? entityId;
  final bool isRead;
  final String createdAt;
  final ProfileModel? actor;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.actorId,
    required this.type,
    this.entityId,
    required this.isRead,
    required this.createdAt,
    this.actor,
  });

  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'message':
        return NotificationType.message;
      case 'club_invite':
        return NotificationType.clubInvite;
      case 'event':
        return NotificationType.event;
      case 'poll':
        return NotificationType.poll;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.unknown;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? actorProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      actorProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      actorId: json['actor_id'] as String?,
      type: _parseType(json['type'] as String?),
      entityId: json['entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      actor: actorProfile,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      actorId: actorId,
      type: type,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actor: actor,
    );
  }
}
