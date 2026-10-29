import 'package:file_picker/file_picker.dart';
import '../models/attachment_model.dart';
import 'profile_service.dart';
import 'storage_service.dart';

/// Thrown with a message that is safe to show to the user.
class ProfileMediaException implements Exception {
  final String message;
  const ProfileMediaException(this.message);

  @override
  String toString() => message;
}

/// Picks an image, uploads it and saves it on the user's profile.
/// Used by both Settings and the "edit cover" button on your own profile,
/// so the logic lives in exactly one place.
class ProfileMediaService {
  static const int maxBytes = 5 * 1024 * 1024; // 5 MB

  final StorageService _storage = StorageService();
  final ProfileService _profiles = ProfileService();

  /// Lets the user choose a cover (background) photo, uploads it and writes
  /// `profiles.cover_url`. Returns the new public URL, or null if the user
  /// cancelled the picker. Throws [ProfileMediaException] / the underlying
  /// error if something goes wrong.
  Future<String?> pickAndSaveCover(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const ProfileMediaException('Could not read that image');
    }
    if (bytes.length > maxBytes) {
      throw const ProfileMediaException('Image is too large (max 5 MB)');
    }

    final dot = file.name.lastIndexOf('.');
    final ext = (dot != -1 && dot < file.name.length - 1)
        ? file.name.substring(dot + 1).toLowerCase()
        : 'jpg';

    final url = await _storage.uploadBytes(
      bucket: 'avatars',
      userId: userId,
      bytes: bytes,
      fileExtension: ext,
      contentType: AttachmentInfo.mimeFromExtension(ext),
      filePrefix: 'cover-',
    );

    await _profiles.updateProfile(userId, {'cover_url': url});
    return url;
  }

  Future<void> removeCover(String userId) async {
    await _profiles.updateProfile(userId, {'cover_url': null});
  }
}
