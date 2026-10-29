import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _notificationService.fetchNotifications(userId);
    } catch (e) {
      print('[NotificationProvider] loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _subscribe(userId);
  }

  void _subscribe(String userId) {
    if (_subscription != null) return;

    _subscription = _notificationService.subscribeToNotifications(userId, (newNotification) {
      _notifications.insert(0, newNotification);
      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
      await _notificationService.markNotificationRead(id);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _notificationService.markAllRead(userId);
  }

  @override
  void dispose() {
    if (_subscription != null) {
      _notificationService.unsubscribe(_subscription!);
    }
    super.dispose();
  }
}
