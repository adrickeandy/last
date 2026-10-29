import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ui_provider.dart';
import '../admin/admin_shell_screen.dart';
import '../clubs/clubs_screen.dart';
import '../confessions/confessions_screen.dart';
import '../events/events_screen.dart';
import '../feed/feed_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../pegasus/pegasus_floating_widget.dart';
import '../pegasus/pegasus_screen.dart';
import '../polls/polls_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'desktop_navbar.dart';
import 'desktop_sidebar.dart';

/// Width (logical px) below which the phone layout is used.
const double kPhoneBreakpoint = 720;

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  Widget _activeScreen(UIProvider ui, AuthProvider auth) {
    switch (ui.currentTab) {
      case AppTab.feed:
        return const FeedScreen();
      case AppTab.search:
        return const SearchScreen();
      case AppTab.messages:
        return const MessagesScreen();
      case AppTab.notifications:
        return const NotificationsScreen();
      case AppTab.clubs:
        return const ClubsScreen();
      case AppTab.events:
        return const EventsScreen();
      case AppTab.marketplace:
        return const MarketplaceScreen();
      case AppTab.confessions:
        return const ConfessionsScreen();
      case AppTab.polls:
        return const PollsScreen();
      case AppTab.pegasus:
        return const PegasusScreen();
      case AppTab.profile:
        return ProfileScreen(
          username: ui.selectedProfileUsername ?? auth.profile?.username ?? '',
        );
      case AppTab.settings:
        return const SettingsScreen();
      case AppTab.admin:
        return const AdminShellScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UIProvider>();
    final auth = context.watch<AuthProvider>();
    final isPhone = MediaQuery.of(context).size.width < kPhoneBreakpoint;

    return isPhone ? _buildPhone(context, ui, auth) : _buildDesktop(ui, auth);
  }

  // ---------------------------------------------------------------------
  // PC / wide layout (unchanged): sidebar + top bar + content
  // ---------------------------------------------------------------------
  Widget _buildDesktop(UIProvider ui, AuthProvider auth) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar Navigation
              const DesktopSidebar(),

              // Main Workspace Area
              Expanded(
                child: Column(
                  children: [
                    const DesktopNavbar(),
                    Expanded(
                      child: Container(
                        alignment: Alignment.topCenter,
                        child: _activeScreen(ui, auth),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Pegasus Assistant Popup
          if (ui.isPegasusFloatingOpen && ui.currentTab != AppTab.pegasus)
            const Positioned(
              right: 24,
              bottom: 24,
              child: PegasusFloatingWidget(),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Phone layout: compact top bar + content + bottom tab bar
  // ---------------------------------------------------------------------
  Widget _buildPhone(BuildContext context, UIProvider ui, AuthProvider auth) {
    // While a chat is open it takes the whole screen (like WhatsApp):
    // no top bar, no bottom tab bar. The chat has its own back arrow.
    final chatFullScreen = ui.currentTab == AppTab.messages && ui.isChatOpen;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      // Only the Feed tab may close the app. Anywhere else, Back steps out:
      // open chat -> conversation list -> Feed -> exit.
      canPop: ui.currentTab == AppTab.feed,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (ui.currentTab == AppTab.messages && ui.isChatOpen) {
          ui.setChatOpen(false);
        } else {
          ui.setTab(AppTab.feed);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  if (!chatFullScreen) const DesktopNavbar(),
                  Expanded(child: _activeScreen(ui, auth)),
                ],
              ),

              // Floating Pegasus Assistant Popup (phone: inset from edges)
              if (ui.isPegasusFloatingOpen && ui.currentTab != AppTab.pegasus)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 24,
                    ),
                    child: const PegasusFloatingWidget(),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar:
            (chatFullScreen || keyboardOpen) ? null : _PhoneBottomBar(ui: ui, auth: auth),
      ),
    );
  }
}

// =========================================================================
// Bottom tab bar (phone only)
// =========================================================================
class _PhoneBottomBar extends StatelessWidget {
  final UIProvider ui;
  final AuthProvider auth;

  const _PhoneBottomBar({required this.ui, required this.auth});

  static const _mainTabs = [
    AppTab.feed,
    AppTab.search,
    AppTab.messages,
    AppTab.notifications,
  ];

  void _openMoreSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <Map<String, dynamic>>[
      {'tab': AppTab.clubs, 'label': 'Clubs', 'icon': Icons.groups_rounded},
      {'tab': AppTab.events, 'label': 'Events', 'icon': Icons.calendar_month_rounded},
      {'tab': AppTab.marketplace, 'label': 'Marketplace', 'icon': Icons.shopping_bag_outlined},
      {'tab': AppTab.confessions, 'label': 'Confessions', 'icon': Icons.lock_outline_rounded},
      {'tab': AppTab.polls, 'label': 'Polls', 'icon': Icons.bar_chart_rounded},
      {'tab': AppTab.pegasus, 'label': 'Pegasus AI', 'icon': Icons.auto_awesome_rounded},
      {'tab': AppTab.settings, 'label': 'Settings', 'icon': Icons.settings_outlined},
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBg950 : AppColors.lightBg950,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (auth.profile != null)
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('My profile'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ui.openProfile(auth.profile!.username);
                    },
                  ),
                for (final item in items)
                  ListTile(
                    leading: Icon(item['icon'] as IconData),
                    title: Text(item['label'] as String),
                    selected: ui.currentTab == item['tab'],
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ui.setTab(item['tab'] as AppTab);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = context.watch<NotificationProvider>().unreadCount;

    // Tabs not on the bar (clubs, events, profile, ...) highlight "More".
    final mainIndex = _mainTabs.indexOf(ui.currentTab);
    final selectedIndex = mainIndex == -1 ? _mainTabs.length : mainIndex;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
          ),
        ),
      ),
      child: NavigationBar(
        height: 62,
        backgroundColor: isDark ? AppColors.darkBg950 : AppColors.lightBg950,
        indicatorColor: AppColors.violet500.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (i == _mainTabs.length) {
            _openMoreSheet(context);
          } else {
            ui.setTab(_mainTabs[i]);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.coral500,
              label: Text(unread > 9 ? '9+' : unread.toString()),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.coral500,
              label: Text(unread > 9 ? '9+' : unread.toString()),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
