import 'profile_model.dart';

class ConversationModel {
  final String id;
  final bool isGroup;
  final String? title;
  final String? createdBy;
  final String createdAt;
  final ProfileModel? otherProfile;

  ConversationModel({
    required this.id,
    required this.isGroup,
    this.title,
    this.createdBy,
    required this.createdAt,
    this.otherProfile,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, {ProfileModel? otherProfile}) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      isGroup: json['is_group'] as bool? ?? false,
      title: json['title'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      otherProfile: otherProfile,
    );
  }
}
