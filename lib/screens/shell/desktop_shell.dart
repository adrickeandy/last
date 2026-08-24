import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UIProvider>();
    final auth = context.watch<AuthProvider>();

    Widget getActiveScreen() {
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
                        child: getActiveScreen(),
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
}
