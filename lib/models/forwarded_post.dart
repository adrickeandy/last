import 'dart:convert';
import 'post_model.dart';

/// A snapshot of a post that was forwarded into a chat.
///
/// It travels inside the normal `messages.content` text column as
/// `[[fwd-post]]{...json...}`, so forwarding needs NO database change and the
/// message still goes through the existing offline-first send/retry path.
/// [MessageBubble] recognises the prefix and draws a post card instead of the
/// raw text; every other part of the app keeps treating it as an ordinary
/// message.
class ForwardedPost {
  static const String prefix = '[[fwd-post]]';

  /// Keep the stored snapshot small.
  static const int _maxTextLength = 600;

  final String? postId;
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String text;
  final String? imageUrl;
  final int imageCount;
  final String? videoUrl;
  final bool isConfession;

  const ForwardedPost({
    this.postId,
    this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    this.text = '',
    this.imageUrl,
    this.imageCount = 0,
    this.videoUrl,
    this.isConfession = false,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory ForwardedPost.fromPost(PostModel post) {
    final isConfession = post.isConfession;
    var text = (post.content ?? '').trim();
    if (text.length > _maxTextLength) {
      text = '${text.substring(0, _maxTextLength).trimRight()}…';
    }

    return ForwardedPost(
      // Posts that have not reached the server yet only have a local id.
      postId: post.id.startsWith('local-') ? null : post.id,
      // Confessions stay anonymous when forwarded.
      authorName: isConfession ? null : (post.author?.fullName ?? post.author?.username),
      authorUsername: isConfession ? null : post.author?.username,
      authorAvatarUrl: isConfession ? null : post.author?.avatarUrl,
      text: text,
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
      imageCount: post.imageUrls.length,
      videoUrl: (post.videoUrl != null && post.videoUrl!.isNotEmpty) ? post.videoUrl : null,
      isConfession: isConfession,
    );
  }

  /// The string stored in `messages.content`.
  String encode() {
    final map = <String, dynamic>{
      if (postId != null) 'id': postId,
      if (authorName != null) 'n': authorName,
      if (authorUsername != null) 'u': authorUsername,
      if (authorAvatarUrl != null) 'a': authorAvatarUrl,
      if (text.isNotEmpty) 't': text,
      if (imageUrl != null) 'i': imageUrl,
      if (imageCount > 0) 'ic': imageCount,
      if (videoUrl != null) 'v': videoUrl,
      if (isConfession) 'c': true,
    };
    return '$prefix${jsonEncode(map)}';
  }

  /// Returns null when [content] is an ordinary message.
  static ForwardedPost? tryParse(String content) {
    if (!content.startsWith(prefix)) return null;
    try {
      final decoded = jsonDecode(content.substring(prefix.length));
      if (decoded is! Map<String, dynamic>) return null;
      return ForwardedPost(
        postId: decoded['id'] as String?,
        authorName: decoded['n'] as String?,
        authorUsername: decoded['u'] as String?,
        authorAvatarUrl: decoded['a'] as String?,
        text: (decoded['t'] as String?) ?? '',
        imageUrl: decoded['i'] as String?,
        imageCount: (decoded['ic'] as num?)?.toInt() ?? 0,
        videoUrl: decoded['v'] as String?,
        isConfession: decoded['c'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
