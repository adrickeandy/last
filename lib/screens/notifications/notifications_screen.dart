import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ui_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().loadNotifications(user.id);
      }
    });
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.message:
        return Icons.mail_rounded;
      case NotificationType.clubInvite:
        return Icons.groups_rounded;
      case NotificationType.event:
        return Icons.calendar_month_rounded;
      case NotificationType.poll:
        return Icons.bar_chart_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return AppColors.coral500;
      case NotificationType.comment:
      case NotificationType.message:
        return AppColors.violet400;
      case NotificationType.follow:
        return AppColors.lime400;
      case NotificationType.event:
        return AppColors.coral400;
      default:
        return AppColors.violet400;
    }
  }

  String _getNotificationMessage(NotificationModel n) {
    final actorName = n.actor?.username ?? 'Someone';
    switch (n.type) {
      case NotificationType.like:
        return '$actorName liked your post.';
      case NotificationType.comment:
        return '$actorName commented on your post.';
      case NotificationType.follow:
        return '$actorName started following you.';
      case NotificationType.message:
        return '$actorName sent you a message.';
      case NotificationType.clubInvite:
        return '$actorName invited you to join a club.';
      case NotificationType.event:
        return 'Upcoming campus event reminder.';
      case NotificationType.poll:
        return 'A new campus poll is available for voting.';
      case NotificationType.mention:
        return '$actorName mentioned you.';
      default:
        return 'New campus activity.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final ui = context.read<UIProvider>();
    final items = notifications.notifications;
    final isLoading = notifications.isLoading;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: () async {
            if (auth.user != null) {
              await notifications.loadNotifications(auth.user!.id);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header & Mark All Read action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
                  if (items.any((n) => !n.isRead))
                    TextButton.icon(
                      onPressed: () {
                        if (auth.user != null) {
                          notifications.markAllAsRead(auth.user!.id);
                        }
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.violet400),
                      label: const Text(
                        'Mark all read',
                        style: TextStyle(fontSize: 12.5, color: AppColors.violet400),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Items List
              if (isLoading) ...[
                const SkeletonLoader(height: 60, margin: EdgeInsets.only(bottom: 10)),
                const SkeletonLoader(height: 60, margin: EdgeInsets.only(bottom: 10)),
                const SkeletonLoader(height: 60, margin: EdgeInsets.only(bottom: 10)),
              ] else if (items.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 48, color: isDark ? AppColors.darkInk500 : AppColors.lightInk500),
                      const SizedBox(height: 12),
                      const Text("You're all caught up", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'No new notifications right now.',
                        style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final n in items)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    borderColor: !n.isRead ? AppColors.violet500.withOpacity(0.4) : null,
                    onTap: () {
                      notifications.markAsRead(n.id);
                      if (n.actor?.username != null) {
                        ui.openProfile(n.actor!.username);
                      }
                    },
                    child: Row(
                      children: [
                        // Type Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(n.type).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(n.type),
                            color: _getNotificationColor(n.type),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getNotificationMessage(n),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: !n.isRead ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppFormatters.timeAgo(n.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dot indicator if unread
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.violet400,
                              shape: BoxShape.circle,
                            ),
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
