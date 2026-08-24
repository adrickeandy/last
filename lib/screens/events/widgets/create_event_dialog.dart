import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/event_service.dart';

class CreateEventDialog extends StatefulWidget {
  final Function(EventModel)? onCreated;

  const CreateEventDialog({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {Function(EventModel)? onCreated}) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateEventDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventService = EventService();
  DateTime _startsAt = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startsAt),
      );

      if (pickedTime != null) {
        setState(() {
          _startsAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to create an event', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = await _eventService.createEvent(
        hostId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        startsAt: _startsAt.toUtc().toIso8601String(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call(event);
        ToastOverlay.show(context, 'Event published!', type: ToastType.success);
      }
    } catch (e) {
      print('[CreateEventDialog] error: $e');
      if (mounted) {
        ToastOverlay.show(context, 'Could not create event', type: ToastType.error);
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
                    Text('Host an Event', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GlassTextField(
                  controller: _titleController,
                  labelText: 'Event Title',
                  hintText: 'e.g. Annual Campus Hackathon',
                  validator: (v) => AppValidators.validateRequired(v, 'Title'),
                ),
                const SizedBox(height: 14),

                GlassTextField(
                  controller: _locationController,
                  labelText: 'Location / Venue',
                  hintText: 'e.g. Science Complex Hall B',
                  validator: (v) => AppValidators.validateRequired(v, 'Location'),
                ),
                const SizedBox(height: 14),

                // Date Time Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startsAt.toString().substring(0, 16),
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            const Icon(Icons.calendar_month_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                GlassTextField(
                  controller: _descController,
                  labelText: 'Description',
                  hintText: 'Event agenda, speakers, and schedule…',
                  maxLines: 2,
                  validator: (v) => AppValidators.validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 24),

                GlassButton(
                  width: double.infinity,
                  height: 44,
                  text: 'Publish Event',
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
