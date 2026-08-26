import 'profile_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String createdAt;
  final ProfileModel? author;
  // Same convention as PostModel.isPending: true only for comments created
  // locally that haven't been confirmed by the server yet. Never comes from
  // Supabase itself - defaults to false so nothing existing breaks.
  final bool isPending;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.author,
    this.isPending = false,
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

  /// Serializes for local caching, mirroring the Supabase row shape
  /// (including the embedded `profiles` relation) - same approach as
  /// PostModel.toJson so [LocalCacheService] can treat every entity the
  /// same way.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt,
      'profiles': author?.toJson(),
      'is_pending': isPending,
    };
  }

  /// Deserializes a locally-cached entry (see [toJson]) - same as
  /// [fromJson] but also restores `isPending`, which a raw Supabase row
  /// never carries.
  factory CommentModel.fromCachedJson(Map<String, dynamic> json) {
    final comment = CommentModel.fromJson(json);
    return comment.copyWith(isPending: json['is_pending'] as bool? ?? false);
  }

  CommentModel copyWith({
    String? content,
    ProfileModel? author,
    bool? isPending,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      authorId: authorId,
      content: content ?? this.content,
      createdAt: createdAt,
      author: author ?? this.author,
      isPending: isPending ?? this.isPending,
    );
  }
}
