import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import '../../models/attachment_model.dart';
import '../widgets/toast_overlay.dart';

/// One place that opens the system file picker for message / comment inputs.
class AttachmentPicker {
  /// Largest file we allow in a chat message or comment.
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB

  /// Returns the chosen file, or null if the user cancelled or the file was
  /// rejected (a toast explains why).
  static Future<PickedAttachment?> pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;

    if (!context.mounted) return null;

    if (bytes == null) {
      ToastOverlay.show(context, 'Could not read that file', type: ToastType.error);
      return null;
    }

    if (bytes.length > maxBytes) {
      ToastOverlay.show(
        context,
        'File is too large (max ${maxBytes ~/ (1024 * 1024)} MB)',
        type: ToastType.error,
      );
      return null;
    }

    return PickedAttachment(name: file.name, bytes: bytes);
  }
}
