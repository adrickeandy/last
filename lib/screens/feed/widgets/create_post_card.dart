import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:image_picker/image_picker.dart' show XFile;
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/toast_overlay.dart';
<<<<<<< HEAD
import '../../../models/attachment_model.dart';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../services/storage_service.dart';

class CreatePostCard extends StatefulWidget {
  final bool isConfession;

  const CreatePostCard({super.key, this.isConfession = false});

  @override
  State<CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends State<CreatePostCard> {
  final _textController = TextEditingController();
  final _storageService = StorageService();
  final List<Uint8List> _selectedImageBytes = [];
  final List<String> _selectedImageNames = [];
<<<<<<< HEAD
  // Video chosen from the device (not uploaded until the post is sent).
  PlatformFile? _videoFile;
  bool _isUploading = false;

  /// Largest video we accept (matches the post-videos bucket limit created
  /// by db/migrations/003_post_videos.sql).
  static const int _maxVideoBytes = 50 * 1024 * 1024; // 50 MB

=======
  String? _videoUrl;
  bool _isUploading = false;

>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null && _selectedImageBytes.length < 4) {
            _selectedImageBytes.add(file.bytes!);
            _selectedImageNames.add(file.name);
          }
        }
      });
    }
  }

<<<<<<< HEAD
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      // Videos are big: don't load the whole file into memory just to pick
      // it. The bytes are read once, when the post is actually sent.
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (!mounted) return;

    if (file.path == null && file.bytes == null) {
      ToastOverlay.show(context, 'Could not read that video', type: ToastType.error);
      return;
    }

    if (file.size > _maxVideoBytes) {
      ToastOverlay.show(
        context,
        'Video is too large (max ${_maxVideoBytes ~/ (1024 * 1024)} MB)',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _videoFile = file);
  }

  Future<Uint8List> _readVideoBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    return XFile(file.path!).readAsBytes();
=======
  Future<void> _promptVideoUrl() async {
    final controller = TextEditingController(text: _videoUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBg900,
        title: const Text('Add Video URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/video.mp4',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Attach'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _videoUrl = url;
      });
    }
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
  }

  Future<void> _handlePost() async {
    final content = _textController.text.trim();
<<<<<<< HEAD
    if (content.isEmpty && _selectedImageBytes.isEmpty && _videoFile == null) {
=======
    if (content.isEmpty && _selectedImageBytes.isEmpty && _videoUrl == null) {
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Please sign in to post', type: ToastType.error);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedImageBytes.length; i++) {
        final ext = _selectedImageNames[i].split('.').last;
        final url = await _storageService.uploadBytes(
          bucket: 'post-images',
          userId: user.id,
          bytes: _selectedImageBytes[i],
          fileExtension: ext.isNotEmpty ? ext : 'jpg',
        );
        uploadedUrls.add(url);
      }

<<<<<<< HEAD
      // Upload the chosen video file (if any) and keep its public URL.
      String? uploadedVideoUrl;
      final video = _videoFile;
      if (video != null) {
        try {
          final bytes = await _readVideoBytes(video);
          final rawExt = (video.extension ?? video.name.split('.').last).toLowerCase();
          final ext = rawExt.isNotEmpty ? rawExt : 'mp4';
          uploadedVideoUrl = await _storageService.uploadBytes(
            bucket: 'post-videos',
            userId: user.id,
            bytes: bytes,
            fileExtension: ext,
            contentType: AttachmentInfo.mimeFromExtension(ext),
          );
        } catch (e) {
          print('[CreatePostCard] Video upload failed: $e');
          if (mounted) {
            ToastOverlay.show(
              context,
              'Could not upload the video. Check your connection and try again.',
              type: ToastType.error,
            );
          }
          return;
        }
      }

=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
      final feed = context.read<FeedProvider>();
      final success = await feed.createPost(
        authorId: user.id,
        content: content,
        imageUrls: uploadedUrls,
<<<<<<< HEAD
        videoUrl: uploadedVideoUrl,
=======
        videoUrl: _videoUrl,
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
        isConfession: widget.isConfession,
        authorProfile: context.read<AuthProvider>().profile,
      );

      if (success) {
        _textController.clear();
        setState(() {
          _selectedImageBytes.clear();
          _selectedImageNames.clear();
<<<<<<< HEAD
          _videoFile = null;
=======
          _videoUrl = null;
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
        });
        ToastOverlay.show(
          context,
          widget.isConfession
              ? 'Confession posted anonymously'
              : 'Post published!',
          type: ToastType.success,
        );
      } else {
        // The post is still visible in the feed (saved locally) and will
        // retry automatically — this isn't a real failure, just "not synced
        // yet", so the composer clears the same way and the message reflects
        // that instead of implying the post was lost.
        _textController.clear();
        setState(() {
          _selectedImageBytes.clear();
          _selectedImageNames.clear();
<<<<<<< HEAD
          _videoFile = null;
=======
          _videoUrl = null;
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
        });
        ToastOverlay.show(
          context,
          'Saved — will post automatically once you\'re back online',
          type: ToastType.info,
        );
      }
    } catch (e) {
      print('[CreatePostCard] Error: $e');
      ToastOverlay.show(context, 'Error uploading attachments', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    final placeholder = widget.isConfession
        ? 'Share something anonymously — no names attached…'
        : "What's happening on campus, ${profile?.fullName?.split(' ').first ?? 'there'}?";

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isConfession)
                AvatarView(
                  url: profile?.avatarUrl,
                  name: profile?.fullName ?? profile?.username,
                  size: 38,
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.coral500.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.coral400,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassTextField(
                  controller: _textController,
                  hintText: placeholder,
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ],
          ),

          // Attached Images Preview
          if (_selectedImageBytes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImageBytes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes[i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImageBytes.removeAt(i);
                              _selectedImageNames.removeAt(i);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

<<<<<<< HEAD
          // Attached Video (local file) Indicator
          if (_videoFile != null) ...[
=======
          // Attached Video URL Indicator
          if (_videoUrl != null) ...[
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.violet500.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_rounded, size: 16, color: AppColors.violet400),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
<<<<<<< HEAD
                      _isUploading
                          ? 'Uploading ${_videoFile!.name}…'
                          : '${_videoFile!.name} · ${AttachmentInfo.formatSize(_videoFile!.size)}',
=======
                      'Video attached: ${_videoUrl!.substring(0, _videoUrl!.length.clamp(0, 30))}...',
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.violet300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
<<<<<<< HEAD
                    onTap: _isUploading ? null : () => setState(() => _videoFile = null),
=======
                    onTap: () => setState(() => _videoUrl = null),
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
                    child: const Icon(Icons.close, size: 14, color: AppColors.violet300),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bottom Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Attach Image (up to 4)',
                    icon: const Icon(Icons.image_outlined, size: 20),
                    onPressed: _isUploading ? null : _pickImages,
                  ),
                  IconButton(
<<<<<<< HEAD
                    tooltip: 'Attach Video (up to 50 MB)',
                    icon: const Icon(Icons.videocam_outlined, size: 20),
                    onPressed: _isUploading ? null : _pickVideo,
=======
                    tooltip: 'Attach Video Link',
                    icon: const Icon(Icons.videocam_outlined, size: 20),
                    onPressed: _isUploading ? null : _promptVideoUrl,
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
                  ),
                ],
              ),
              GlassButton(
                text: widget.isConfession ? 'Post anonymously' : 'Post',
                variant: GlassButtonVariant.primary,
                height: 38,
                isLoading: _isUploading,
                onPressed: _handlePost,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
