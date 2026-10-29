import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/forwarded_post.dart';
import '../../providers/ui_provider.dart';
import '../theme/app_colors.dart';
import 'avatar_view.dart';
import 'image_lightbox_dialog.dart';
import 'toast_overlay.dart';

/// Draws a [ForwardedPost] inside a chat message bubble.
///
/// - Tap the author row to open their profile.
/// - Tap the picture to view it full size.
/// - Tap the video row to play it.
class ForwardedPostCard extends StatelessWidget {
  final ForwardedPost post;

  /// True when drawn on the solid violet "my message" bubble, so text and
  /// icons switch to white to stay readable (same convention as
  /// [AttachmentView]).
  final bool onAccent;

  const ForwardedPostCard({
    super.key,
    required this.post,
    this.onAccent = false,
  });

  Future<void> _playVideo(BuildContext context) async {
    final uri = Uri.tryParse(post.videoUrl ?? '');
    var ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && context.mounted) {
      ToastOverlay.show(context, 'Could not open video', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = onAccent
        ? Colors.white
        : (isDark ? AppColors.darkInk100 : AppColors.lightInk100);
    final sub = onAccent
        ? Colors.white.withOpacity(0.75)
        : (isDark ? AppColors.darkInk400 : AppColors.lightInk400);
    final panel = onAccent
        ? Colors.white.withOpacity(0.15)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05));

    final name = post.isConfession
        ? 'Anonymous Student'
        : (post.authorName ?? post.authorUsername ?? 'Student');
    final canOpenProfile = !post.isConfession && post.authorUsername != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: onAccent ? Colors.white.withOpacity(0.7) : AppColors.violet400,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Forwarded post" label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shortcut_rounded, size: 12, color: sub),
                const SizedBox(width: 4),
                Text(
                  'Forwarded post',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Author
            InkWell(
              onTap: canOpenProfile
                  ? () => context.read<UIProvider>().openProfile(post.authorUsername!)
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (post.isConfession)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.coral500.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: AppColors.coral400,
                      ),
                    )
                  else
                    AvatarView(
                      url: post.authorAvatarUrl,
                      name: name,
                      size: 24,
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.text,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.35, color: fg),
              ),
            ],

            // First picture (with "+N" when the post has several)
            if (post.imageUrl != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ImageLightboxDialog.show(context, [post.imageUrl!]),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 150,
                            color: Colors.black12,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.black12,
                            child: const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                        if (post.imageCount > 1)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+${post.imageCount - 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Video
            if (post.hasVideo) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _playVideo(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, size: 22, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Play video',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: onAccent ? Colors.white : fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
