import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/club_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/club_service.dart';

class CreateClubDialog extends StatefulWidget {
  final Function(ClubModel)? onCreated;

  const CreateClubDialog({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {Function(ClubModel)? onCreated}) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateClubDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends State<CreateClubDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _clubService = ClubService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to create a club', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final club = await _clubService.createClub(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        createdBy: user.id,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call(club);
        ToastOverlay.show(context, 'Club created successfully!', type: ToastType.success);
      }
    } catch (e) {
      print('[CreateClubDialog] error: $e');
      if (mounted) {
        ToastOverlay.show(context, 'Could not create club', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start a Campus Club', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GlassTextField(
                  controller: _nameController,
                  labelText: 'Club Name',
                  hintText: 'e.g. AI & Robotics Guild',
                  validator: (v) => AppValidators.validateRequired(v, 'Club name'),
                ),
                const SizedBox(height: 14),

                GlassTextField(
                  controller: _descController,
                  labelText: 'Description',
                  hintText: 'What is this club about and who should join?',
                  maxLines: 3,
                  validator: (v) => AppValidators.validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 24),

                GlassButton(
                  width: double.infinity,
                  height: 44,
                  text: 'Create Club',
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
