import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import 'widgets/create_event_dialog.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _eventService = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = context.read<AuthProvider>().user;
    final list = await _eventService.fetchUpcomingEvents(currentUserId: user?.id);
    if (mounted) {
      setState(() {
        _events = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRsvp(EventModel event) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to RSVP', type: ToastType.info);
      return;
    }

    final isGoing = !event.isGoing;
    final newCount = event.rsvpCount + (isGoing ? 1 : -1);

    setState(() {
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event.copyWith(
          isGoing: isGoing,
          rsvpCount: newCount < 0 ? 0 : newCount,
        );
      }
    });

    try {
      await _eventService.rsvpToEvent(
        eventId: event.id,
        userId: user.id,
        status: isGoing ? 'going' : 'declined',
      );
      ToastOverlay.show(
        context,
        isGoing ? "You're going to ${event.title}" : 'RSVP updated',
        type: ToastType.success,
      );
    } catch (e) {
      print('[EventsScreen] rsvp error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Conferences, workshops, socials, and club meetups.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                  GlassButton(
                    variant: GlassButtonVariant.primary,
                    text: 'Host event',
                    icon: Icons.add_rounded,
                    height: 38,
                    onPressed: () {
                      if (auth.user == null) {
                        ToastOverlay.show(context, 'Sign in to create an event', type: ToastType.info);
                        return;
                      }
                      CreateEventDialog.show(
                        context,
                        onCreated: (newEvent) {
                          setState(() => _events.insert(0, newEvent));
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Events List
              if (_isLoading) ...[
                const SkeletonLoader(height: 84, margin: EdgeInsets.only(bottom: 12)),
                const SkeletonLoader(height: 84, margin: EdgeInsets.only(bottom: 12)),
                const SkeletonLoader(height: 84, margin: EdgeInsets.only(bottom: 12)),
              ] else if (_events.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 48, color: AppColors.lime400),
                      const SizedBox(height: 12),
                      const Text('No upcoming events scheduled', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to host a campus event.',
                        style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final ev in _events)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Date badge
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.violet500.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppFormatters.getMonthShort(ev.startsAt),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.violet400,
                                ),
                              ),
                              Text(
                                AppFormatters.getDayNumber(ev.startsAt),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.violet300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (ev.location != null && ev.location!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.coral400),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ev.location!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                              ],
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.lime400),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppFormatters.formatEventDate(ev.startsAt),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                    ),
                                  ),
                                  if (ev.rsvpCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '· ${ev.rsvpCount} going',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.violet300),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // RSVP Button
                        GlassButton(
                          variant: ev.isGoing ? GlassButtonVariant.secondary : GlassButtonVariant.primary,
                          text: ev.isGoing ? 'Going' : 'RSVP',
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () => _handleRsvp(ev),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
