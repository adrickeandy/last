import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService.client;
  final Uuid _uuid = const Uuid();

  Future<String> uploadBytes({
    required String bucket,
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    String? contentType,
  }) async {
    final fileName = '$userId/${_uuid.v4()}.$fileExtension';

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
}
