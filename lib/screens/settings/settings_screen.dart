import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService = ProfileService();
  final _storageService = StorageService();

  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _campusController;
  late TextEditingController _courseController;

  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _campusController = TextEditingController(text: profile?.campus ?? '');
    _courseController = TextEditingController(text: profile?.course ?? '');
    _avatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _campusController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      final file = result.files.first;
      setState(() => _isUploadingPhoto = true);

      try {
        final ext = file.name.split('.').last;
        final url = await _storageService.uploadBytes(
          bucket: 'avatars',
          userId: user.id,
          bytes: file.bytes!,
          fileExtension: ext.isNotEmpty ? ext : 'jpg',
        );

        await _profileService.updateProfile(user.id, {'avatar_url': url});
        await auth.refreshProfile();

        setState(() => _avatarUrl = url);
        ToastOverlay.show(context, 'Profile picture updated!', type: ToastType.success);
      } catch (e) {
        print('[SettingsScreen] Photo upload error: $e');
        ToastOverlay.show(context, 'Could not upload photo', type: ToastType.error);
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(user.id, {
        'full_name': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'campus': _campusController.text.trim(),
        'course': _courseController.text.trim(),
      });

      await auth.refreshProfile();
      ToastOverlay.show(context, 'Profile settings updated!', type: ToastType.success);
    } catch (e) {
      print('[SettingsScreen] Save error: $e');
      ToastOverlay.show(context, 'Could not save profile', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBg900,
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of CampusX?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral500),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      ToastOverlay.show(context, 'Signed out of CampusX', type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Account Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Row
                  Row(
                    children: [
                      AvatarView(
                        url: _avatarUrl,
                        name: profile?.fullName ?? profile?.username,
                        size: 64,
                        showRing: true,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassButton(
                            variant: GlassButtonVariant.secondary,
                            text: 'Change photo',
                            icon: Icons.camera_alt_outlined,
                            height: 38,
                            isLoading: _isUploadingPhoto,
                            onPressed: _pickAndUploadPhoto,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPG, PNG or GIF up to 5MB',
                            style: TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Fields
                  GlassTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
                    hintText: 'e.g. Alex Morgan',
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _campusController,
                    labelText: 'Campus / College',
                    hintText: 'e.g. Main Campus / Engineering',
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _courseController,
                    labelText: 'Course / Major',
                    hintText: 'e.g. Computer Science & Software Eng.',
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _bioController,
                    labelText: 'Bio',
                    hintText: 'A little bit about yourself, interests, and year…',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  GlassButton(
                    width: double.infinity,
                    height: 44,
                    text: 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sign out button
            GlassButton(
              variant: GlassButtonVariant.danger,
              width: double.infinity,
              height: 44,
              text: 'Sign out of CampusX',
              icon: Icons.logout_rounded,
              onPressed: _handleSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
