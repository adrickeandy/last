import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ui_provider.dart';

class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({super.key});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  static const double _collapsedWidth = 72;
  static const double _expandedWidth = 250;
  static const Duration _animDuration = Duration(milliseconds: 180);

  bool _hovering = false;
  // Pinned open via the dedicated pin icon — deliberately a *separate*
  // control from the logo, which is reserved for the blueprint's hidden
  // 5-taps-in-3-seconds admin trigger (see UIProvider.handleLogoClick).
  // Conflating the two (e.g. via long-press) would interfere with that
  // trigger's timing, so pin/unpin never touches the logo's tap handler.
  bool _pinned = false;

  bool get _isExpanded => _pinned || _hovering;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ui = context.watch<UIProvider>();
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final profile = auth.profile;
    final expanded = _isExpanded;

    final navItems = [
      {'tab': AppTab.feed, 'label': 'Feed', 'icon': Icons.home_rounded},
      {'tab': AppTab.search, 'label': 'Search', 'icon': Icons.search_rounded},
      {'tab': AppTab.messages, 'label': 'Messages', 'icon': Icons.chat_bubble_outline_rounded},
      {'tab': AppTab.notifications, 'label': 'Notifications', 'icon': Icons.notifications_none_rounded, 'badge': notifications.unreadCount},
      {'tab': AppTab.clubs, 'label': 'Clubs', 'icon': Icons.groups_rounded},
      {'tab': AppTab.events, 'label': 'Events', 'icon': Icons.calendar_month_rounded},
      {'tab': AppTab.marketplace, 'label': 'Marketplace', 'icon': Icons.shopping_bag_outlined},
      {'tab': AppTab.confessions, 'label': 'Confessions', 'icon': Icons.lock_outline_rounded},
      {'tab': AppTab.polls, 'label': 'Polls', 'icon': Icons.bar_chart_rounded},
      {'tab': AppTab.pegasus, 'label': 'Pegasus AI', 'icon': Icons.auto_awesome_rounded, 'isAi': true},
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOut,
        width: expanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg950 : AppColors.lightBg950,
          border: Border(
            right: BorderSide(
              color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 12, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CampusX logo — a normal click always goes home, and also
            // feeds the blueprint's hidden 5-taps-in-3-seconds admin
            // trigger. Pinning the sidebar open is the separate pin icon
            // below, on purpose (see class doc above).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment:
                    expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => ui.handleLogoClick(auth.isAdmin, context),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CampusX',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    Tooltip(
                      message: _pinned ? 'Unpin sidebar' : 'Pin sidebar open',
                      child: InkWell(
                        onTap: () => setState(() => _pinned = !_pinned),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 16,
                            color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nav Items
            Expanded(
              child: ListView.separated(
                itemCount: navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final item = navItems[i];
                  final tab = item['tab'] as AppTab;
                  final isSelected = ui.currentTab == tab;
                  final isAi = item['isAi'] == true;
                  final badgeCount = (item['badge'] as int?) ?? 0;
                  final label = item['label'] as String;

                  final icon = isAi
                      ? ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.pegasusGradient.createShader(bounds),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? (isDark ? AppColors.darkInk100 : AppColors.lightInk100)
                              : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                        );

                  final row = Row(
                    mainAxisAlignment:
                        expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          icon,
                          if (!expanded && badgeCount > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.coral500,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (expanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.darkInk100 : AppColors.lightInk100)
                                  : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                            ),
                          ),
                        ),
                        if (badgeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coral500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ],
                  );

                  final navTile = Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ui.setTab(tab),
                      borderRadius: BorderRadius.circular(14),
                      hoverColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.03),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: expanded ? 14 : 0,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.violet500.withOpacity(0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.violet500.withOpacity(0.4),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: row,
                      ),
                    ),
                  );

                  return expanded ? navTile : Tooltip(message: label, child: navTile);
                },
              ),
            ),

            // User Profile Quick Bar at bottom
            if (profile != null)
              expanded
                  ? GlassContainer(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 16,
                      onTap: () => ui.openProfile(profile.username),
                      child: Row(
                        children: [
                          AvatarView(
                            url: profile.avatarUrl,
                            name: profile.fullName ?? profile.username,
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.fullName ?? profile.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '@${profile.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            onPressed: () => ui.setTab(AppTab.settings),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    )
                  : Tooltip(
                      message: '${profile.fullName ?? profile.username} — @${profile.username}',
                      child: GestureDetector(
                        onTap: () => ui.openProfile(profile.username),
                        child: Center(
                          child: AvatarView(
                            url: profile.avatarUrl,
                            name: profile.fullName ?? profile.username,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
