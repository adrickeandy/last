import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/avatar_view.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ui_provider.dart';

class DesktopNavbar extends StatelessWidget {
  const DesktopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final ui = context.watch<UIProvider>();
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final profile = auth.profile;

    String getTabTitle() {
      switch (ui.currentTab) {
        case AppTab.feed:
          return 'Campus Feed';
        case AppTab.search:
          return 'Search Campus';
        case AppTab.messages:
          return 'Direct Messages';
        case AppTab.notifications:
          return 'Notifications';
        case AppTab.clubs:
          return 'Clubs & Communities';
        case AppTab.events:
          return 'Upcoming Events';
        case AppTab.marketplace:
          return 'Marketplace';
        case AppTab.confessions:
          return 'Confessions';
        case AppTab.polls:
          return 'Campus Polls';
        case AppTab.pegasus:
          return 'Pegasus AI Assistant';
        case AppTab.profile:
          return 'Profile';
        case AppTab.settings:
          return 'Settings';
        case AppTab.admin:
          return 'Admin Console';
      }
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg950 : AppColors.lightBg950,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Page Title
          Text(
            getTabTitle(),
            style: Theme.of(context).textTheme.titleLarge,
          ),

          // Action Items (Search shortcut, AI floating toggle, Theme switch, Notifications, User)
          Row(
            children: [
              // Pegasus AI Quick Floating Launcher
              IconButton(
                tooltip: 'Toggle Pegasus AI Assistant',
                onPressed: () => ui.togglePegasusFloating(),
                icon: ShaderMask(
                  shaderCallback: (bounds) => AppColors.pegasusGradient.createShader(bounds),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),

              // Theme Mode Switcher
              IconButton(
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),

              // Notifications
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => ui.setTab(AppTab.notifications),
                    icon: const Icon(Icons.notifications_none_rounded, size: 20),
                  ),
                  if (notifications.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral500,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Avatar
              if (profile != null)
                AvatarView(
                  url: profile.avatarUrl,
                  name: profile.fullName ?? profile.username,
                  size: 32,
                  onTap: () => ui.openProfile(profile.username),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
