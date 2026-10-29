import 'dart:typed_data';

/// A file the user just picked (still in memory, not uploaded yet).
class PickedAttachment {
  final String name;
  final Uint8List bytes;

  const PickedAttachment({required this.name, required this.bytes});

  int get size => bytes.length;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'bin';
    return name.substring(dot + 1).toLowerCase();
  }

  String get mimeType => AttachmentInfo.mimeFromExtension(extension);

  bool get isImage => mimeType.startsWith('image/');
}

/// A file that has been uploaded and is attached to a message or comment.
///
/// Stored in the database as four flat columns on `messages` / `comments`:
/// attachment_url, attachment_name, attachment_type, attachment_size.
class AttachmentInfo {
  final String url;
  final String name;
  final String? type; // MIME type, e.g. image/png
  final int? size; // bytes

  const AttachmentInfo({
    required this.url,
    required this.name,
    this.type,
    this.size,
  });

  bool get isImage =>
      (type ?? mimeFromExtension(name.split('.').last)).startsWith('image/');

  /// Reads the four attachment_* columns out of a Supabase row.
  /// Returns null when the row has no attachment.
  static AttachmentInfo? fromJson(Map<String, dynamic> json) {
    final url = json['attachment_url'] as String?;
    if (url == null || url.isEmpty) return null;
    final rawSize = json['attachment_size'];
    return AttachmentInfo(
      url: url,
      name: (json['attachment_name'] as String?) ?? 'file',
      type: json['attachment_type'] as String?,
      size: rawSize is num ? rawSize.toInt() : null,
    );
  }

  /// The attachment_* columns, ready to merge into an insert payload / cache.
  Map<String, dynamic> toColumns() => {
        'attachment_url': url,
        'attachment_name': name,
        'attachment_type': type,
        'attachment_size': size,
      };

  static String mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
<<<<<<< HEAD
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'm4v':
        return 'video/x-m4v';
      case '3gp':
        return 'video/3gpp';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
      default:
        return 'application/octet-stream';
    }
  }

  static String formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
