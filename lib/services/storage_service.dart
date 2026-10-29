import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment_model.dart';
import 'supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService.client;
  final Uuid _uuid = const Uuid();

  /// Bucket used for files sent in chats and comments. Created by
  /// db/migrations/002_likes_dms_attachments.sql.
  static const String attachmentsBucket = 'attachments';

  Future<String> uploadBytes({
    required String bucket,
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    String? contentType,
    // Optional file-name prefix, e.g. 'cover-' so a cover photo and an
    // avatar can live in the same bucket/folder without colliding.
    String filePrefix = '',
  }) async {
    final fileName = '$userId/$filePrefix${_uuid.v4()}.$fileExtension';

    await _client.storage.from(bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType ?? 'image/$fileExtension',
        upsert: true,
      ),
    );

    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  /// Uploads a picked file for a chat message or comment and returns the
  /// info needed to attach it. The storage path starts with the user's id
  /// (the bucket policy only lets you write into your own folder).
  Future<AttachmentInfo> uploadAttachment({
    required String userId,
    required PickedAttachment file,
  }) async {
    final path = '$userId/${_uuid.v4()}.${file.extension}';

    await _client.storage.from(attachmentsBucket).uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(
            contentType: file.mimeType,
            upsert: false,
          ),
        );

    final url = _client.storage.from(attachmentsBucket).getPublicUrl(path);

    return AttachmentInfo(
      url: url,
      name: file.name,
      type: file.mimeType,
      size: file.size,
    );
  }
}
