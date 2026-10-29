import 'profile_model.dart';
import 'post_model.dart';

class AdminLogModel {
  final String id;
  final String? adminId;
  final String action;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> meta;
  final String createdAt;

  AdminLogModel({
    required this.id,
    this.adminId,
    required this.action,
    this.targetType,
    this.targetId,
    this.meta = const {},
    required this.createdAt,
  });

  factory AdminLogModel.fromJson(Map<String, dynamic> json) {
    return AdminLogModel(
      id: json['id'] as String? ?? '',
      adminId: json['admin_id'] as String?,
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      meta: (json['meta'] is Map) ? Map<String, dynamic>.from(json['meta']) : {},
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class FeatureFlagModel {
  final String key;
  final bool enabled;
  final String? description;
  final String? updatedBy;
  final String updatedAt;

  FeatureFlagModel({
    required this.key,
    required this.enabled,
    this.description,
    this.updatedBy,
    required this.updatedAt,
  });

  factory FeatureFlagModel.fromJson(Map<String, dynamic> json) {
    return FeatureFlagModel(
      key: json['key'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      description: json['description'] as String?,
      updatedBy: json['updated_by'] as String?,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class ReportModel {
  final String id;
  final String reporterId;
  final String targetType; // 'post', 'user', 'comment'
  final String targetId;
  final String reason;
  final String status; // 'pending', 'resolved', 'dismissed'
  final String createdAt;
  final ProfileModel? reporter;
  final PostModel? post;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporter,
    this.post,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? reporterProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      reporterProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    PostModel? postItem;
    if (json['posts'] != null && json['posts'] is Map<String, dynamic>) {
      postItem = PostModel.fromJson(json['posts'] as Map<String, dynamic>);
    }

    return ReportModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      reporter: reporterProfile,
      post: postItem,
    );
  }
}
