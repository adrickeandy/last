import 'package:flutter/material.dart';

enum AppTab {
  feed,
  search,
  messages,
  notifications,
  clubs,
  events,
  marketplace,
  confessions,
  polls,
  pegasus,
  profile,
  settings,
  admin,
}

class UIProvider extends ChangeNotifier {
  AppTab _currentTab = AppTab.feed;
  String? _selectedProfileUsername;
  int _logoClickCount = 0;
  DateTime? _lastLogoClickTime;
  bool _isPegasusFloatingOpen = false;

  AppTab get currentTab => _currentTab;
  String? get selectedProfileUsername => _selectedProfileUsername;
  bool get isPegasusFloatingOpen => _isPegasusFloatingOpen;

  void setTab(AppTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void openProfile(String username) {
    _selectedProfileUsername = username;
    _currentTab = AppTab.profile;
    notifyListeners();
  }

  void togglePegasusFloating() {
    _isPegasusFloatingOpen = !_isPegasusFloatingOpen;
    notifyListeners();
  }

  void setPegasusFloating(bool isOpen) {
    _isPegasusFloatingOpen = isOpen;
    notifyListeners();
  }

  /// Hidden admin entrance triggered by clicking the CampusX logo 5 times
  /// within 3 seconds (see blueprint §25). Every click also navigates home
  /// like a normal logo click — the secret sequence rides on top of that
  /// ordinary behavior rather than replacing it, so nothing about the UI
  /// changes for someone who isn't intentionally triggering it.
  void handleLogoClick(bool isAdmin, BuildContext context) {
    final now = DateTime.now();
    if (_lastLogoClickTime == null || now.difference(_lastLogoClickTime!).inSeconds > 3) {
      _logoClickCount = 1;
    } else {
      _logoClickCount++;
    }
    _lastLogoClickTime = now;

    if (_logoClickCount >= 5) {
      _logoClickCount = 0;
      // Per blueprint §25: non-admins must see absolutely no indication
      // this gesture is special — no snackbar, no toast, no error. Silence
      // is the only acceptable outcome here; admins are routed to the
      // dashboard, everyone else falls through with no visible effect.
      if (isAdmin) {
        setTab(AppTab.admin);
      }
    } else {
      setTab(AppTab.feed);
    }
  }
}
