import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/poll_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/poll_service.dart';

class CreatePollDialog extends StatefulWidget {
  final Function(PollModel)? onCreated;

  const CreatePollDialog({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {Function(PollModel)? onCreated}) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreatePollDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final _pollService = PollService();
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final c = _optionControllers.removeAt(index);
        c.dispose();
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to create a poll', type: ToastType.error);
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ToastOverlay.show(context, 'Provide at least 2 options', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final poll = await _pollService.createPoll(
        authorId: user.id,
        question: _questionController.text.trim(),
        options: options,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call(poll);
        ToastOverlay.show(context, 'Poll published!', type: ToastType.success);
      }
    } catch (e) {
      print('[CreatePollDialog] error: $e');
      if (mounted) {
        ToastOverlay.show(context, 'Could not create poll', type: ToastType.error);
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
        constraints: const BoxConstraints(maxWidth: 460),
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
                    Text('Create a Campus Poll', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GlassTextField(
                  controller: _questionController,
                  labelText: 'Question',
                  hintText: 'What is your opinion on…',
                  validator: (v) => AppValidators.validateRequired(v, 'Question'),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Options',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                Column(
                  children: List.generate(_optionControllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _optionControllers[i],
                              hintText: 'Option ${i + 1}',
                              validator: (v) => AppValidators.validateRequired(v, 'Option ${i + 1}'),
                            ),
                          ),
                          if (_optionControllers.length > 2) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.white54),
                              onPressed: () => _removeOption(i),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),

                if (_optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add option', style: TextStyle(fontSize: 13)),
                  ),

                const SizedBox(height: 20),

                GlassButton(
                  width: double.infinity,
                  height: 44,
                  text: 'Publish Poll',
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
