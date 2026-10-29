import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // Phone: smaller bar, no notifications bell (it's in the bottom tab bar).
    final compact = MediaQuery.of(context).size.width < 720;

    String getTabTitle() {
      switch (ui.currentTab) {
        case AppTab.feed:
          return 'Plateau High Zone';
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

    final gap = compact ? 0.0 : 8.0;

    return Container(
      height: compact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
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
        children: [
          // Current Page Title (shrinks with an ellipsis instead of overflowing)
          Expanded(
            child: ui.currentTab == AppTab.feed
                // Feed header: "Plateau High Zone" as a handwritten,
                // Instagram-style wordmark with the brand gradient.
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      child: Text(
                        'Plateau High Zone',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.getFont(
                          'Grand Hotel',
                          fontSize: compact ? 30 : 36,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    getTabTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)
                        : Theme.of(context).textTheme.titleLarge,
                  ),
          ),

          // Action Items (AI floating toggle, Theme switch, Notifications, User)
          Row(
            mainAxisSize: MainAxisSize.min,
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
              SizedBox(width: gap),

              // Theme Mode Switcher
              IconButton(
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
              ),
              SizedBox(width: gap),

              // Notifications (desktop only; phones use the bottom tab bar)
              if (!compact) ...[
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
              ],

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
