import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/attachment_model.dart';
import '../theme/app_colors.dart';
import 'image_lightbox_dialog.dart';
import 'toast_overlay.dart';

IconData _iconFor(String name, String? mime) {
  final type = mime ?? AttachmentInfo.mimeFromExtension(name.split('.').last);
  if (type.startsWith('image/')) return Icons.image_outlined;
  if (type.startsWith('video/')) return Icons.movie_outlined;
  if (type.startsWith('audio/')) return Icons.audiotrack_outlined;
  if (type == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (type == 'application/zip') return Icons.folder_zip_outlined;
  return Icons.insert_drive_file_outlined;
}

/// Renders an uploaded attachment inside a message bubble or a comment:
/// images show as a tappable preview (opens the lightbox), everything else
/// as a small file card that opens the file when tapped.
class AttachmentView extends StatelessWidget {
  final AttachmentInfo attachment;

  /// True when drawn on the solid violet "my message" bubble, so text and
  /// icons switch to white to stay readable.
  final bool onAccent;

  const AttachmentView({
    super.key,
    required this.attachment,
    this.onAccent = false,
  });

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(attachment.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ToastOverlay.show(context, 'Could not open file', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (attachment.isImage) {
      return GestureDetector(
        onTap: () => ImageLightboxDialog.show(context, [attachment.url]),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 220),
              child: CachedNetworkImage(
                imageUrl: attachment.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 200,
                  height: 140,
                  color: Colors.black12,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 200,
                  height: 100,
                  color: Colors.black12,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final fg = onAccent
        ? Colors.white
        : (isDark ? AppColors.darkInk100 : AppColors.lightInk100);
    final sub = onAccent
        ? Colors.white.withOpacity(0.75)
        : (isDark ? AppColors.darkInk400 : AppColors.lightInk400);

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: onAccent
              ? Colors.white.withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(attachment.name, attachment.type), size: 22, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (attachment.size != null)
                    Text(
                      AttachmentInfo.formatSize(attachment.size),
                      style: TextStyle(fontSize: 10.5, color: sub),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.download_rounded, size: 16, color: sub),
          ],
        ),
      ),
    );
  }
}

/// Shows the file the user has picked but not sent yet, just above a
/// message / comment input, with a button to remove it.
class PendingAttachmentChip extends StatelessWidget {
  final PickedAttachment file;
  final bool isUploading;
  final VoidCallback? onRemove;

  const PendingAttachmentChip({
    super.key,
    required this.file,
    this.isUploading = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
        ),
      ),
      child: Row(
        children: [
          if (file.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                file.bytes,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 40, height: 40, child: Icon(Icons.image_outlined)),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.violet500.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconFor(file.name, file.mimeType),
                size: 20,
                color: AppColors.violet400,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  isUploading ? 'Uploading…' : AttachmentInfo.formatSize(file.size),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                  ),
                ),
              ],
            ),
          ),
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Remove attachment',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
