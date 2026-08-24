import 'profile_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String createdAt;
  final ProfileModel? author;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? authorProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      authorProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return CommentModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      author: authorProfile,
    );
  }
}
