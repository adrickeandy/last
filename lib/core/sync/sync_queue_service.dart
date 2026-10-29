import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'sync_queue_item.dart';

typedef SyncHandler = Future<void> Function(SyncQueueItem item);

/// Offline write queue for posts, comments, messages, etc.
///
/// Same storage approach as [LocalCacheService] (shared_preferences, no
/// native plugins) - see that file's header comment for why. Exposed as a
/// [ChangeNotifier] so it slots into the existing `MultiProvider` in
/// `app.dart` the same way AuthProvider/FeedProvider/ChatProvider do, while
/// also being reachable as a plain singleton (`SyncQueueService.instance`)
/// from services like PostService/MessageService that aren't part of the
/// widget tree.
///
/// How it works:
/// 1. A service builds a "pending" local record (isPending = true) and
///    calls [enqueue] with what's needed to replay the write later.
/// 2. This queue tries the write immediately, then on a periodic timer,
///    then whenever [retry] is called from a UI button.
/// 3. Deliberately no connectivity plugin: we just attempt the write and
///    catch failures. A real network error looks identical to "offline"
///    from here, and both are handled the same way - retry with backoff.
class SyncQueueService extends ChangeNotifier {
  SyncQueueService._internal();
  static final SyncQueueService instance = SyncQueueService._internal();

  static const _queueKey = 'sync_queue_v1';
  static const _maxAutoRetries = 8;

  final _uuid = const Uuid();
  final Map<String, SyncHandler> _handlers = {};

  List<SyncQueueItem> _queue = [];
  bool _isProcessing = false;
  Timer? _timer;
  bool _initialized = false;

  List<SyncQueueItem> get queue => List.unmodifiable(_queue);

  List<SyncQueueItem> get failedItems =>
      _queue.where((i) => i.status == 'failed').toList();

  List<SyncQueueItem> get pendingItems =>
      _queue.where((i) => i.status == 'pending' || i.status == 'syncing').toList();

  /// Look up queue state for one locally-created record (post/comment/
  /// message) by the id it was created with. Null once it's synced.
  SyncQueueItem? statusFor(String localId) {
    try {
      return _queue.firstWhere((i) => i.id == localId);
    } catch (_) {
      return null;
    }
  }

  /// Call once at app startup, before runApp (see main.dart).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadQueue();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => processQueue());
    unawaited(processQueue()); // catch up on anything left over from last session
  }

  /// Call once per entity type at startup, after [init] - see
  /// lib/core/sync/sync_handlers.dart (to be added once we wire real
  /// entity types in).
  void registerHandler(String entityType, SyncHandler handler) {
    _handlers[entityType] = handler;
  }

  String newLocalId() => _uuid.v4();

  Future<SyncQueueItem> enqueue({
    String? id,
    required String entityType,
    required String opType,
    required Map<String, dynamic> payload,
    List<String> localImagePaths = const [],
  }) async {
    final now = DateTime.now();
    final item = SyncQueueItem(
      id: id ?? newLocalId(),
      entityType: entityType,
      opType: opType,
      payload: payload,
      localImagePaths: localImagePaths,
      createdAt: now,
      nextAttemptAt: now,
    );
    _queue.add(item);
    await _saveQueue();
    notifyListeners();
    unawaited(processQueue());
    return item;
  }

  /// Wire this to a retry button.
  Future<void> retry(String id) async {
    final index = _queue.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _queue[index] = _queue[index].copyWith(
      status: 'pending',
      retryCount: 0,
      nextAttemptAt: DateTime.now(),
      lastError: null,
    );
    await _saveQueue();
    notifyListeners();
    unawaited(processQueue());
  }

  Future<void> retryAllFailed() async {
    final now = DateTime.now();
    _queue = _queue
        .map((i) => i.status == 'failed'
            ? i.copyWith(status: 'pending', retryCount: 0, nextAttemptAt: now, lastError: null)
            : i)
        .toList();
    await _saveQueue();
    notifyListeners();
    unawaited(processQueue());
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final now = DateTime.now();
      final due = _queue
          .where((i) =>
              (i.status == 'pending' || i.status == 'failed') &&
              !i.nextAttemptAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final item in due) {
        await _processOne(item);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processOne(SyncQueueItem original) async {
    final handler = _handlers[original.entityType];
    if (handler == null) return; // no handler registered yet - stay queued

    _updateItem(original.id, (i) => i.copyWith(status: 'syncing'));
    notifyListeners();

    try {
      await handler(original);
      _queue.removeWhere((i) => i.id == original.id); // done - drop from queue
      await _saveQueue();
    } catch (e) {
      final current = statusFor(original.id) ?? original;
      final nextRetryCount = current.retryCount + 1;
      final tooManyAttempts = nextRetryCount >= _maxAutoRetries;
      final backoffSeconds = _backoffSeconds(nextRetryCount);
      _updateItem(
        original.id,
        (i) => i.copyWith(
          status: 'failed',
          retryCount: nextRetryCount,
          // Past the auto-retry cap, park it far in the future - it only
          // moves again via a manual retry() call from the UI.
          nextAttemptAt: tooManyAttempts
              ? DateTime.now().add(const Duration(days: 3650))
              : DateTime.now().add(Duration(seconds: backoffSeconds)),
          lastError: e.toString(),
        ),
      );
      await _saveQueue();
      if (kDebugMode) {
        print('[SyncQueueService] ${original.entityType}:${original.id} failed: $e');
      }
    }
    notifyListeners();
  }

  int _backoffSeconds(int retryCount) {
    // 5s, 10s, 20s, 40s ... capped at 5 minutes.
    final seconds = 5 * (1 << (retryCount - 1).clamp(0, 6));
    return seconds > 300 ? 300 : seconds;
  }

  void _updateItem(String id, SyncQueueItem Function(SyncQueueItem) update) {
    final index = _queue.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _queue[index] = update(_queue[index]);
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) {
        _queue = [];
        return;
      }
      final decoded = jsonDecode(raw) as List;
      _queue = decoded.map((e) => SyncQueueItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // Same philosophy as LocalCacheService: a corrupted queue should never
      // crash the app - just start empty and let new writes repopulate it.
      print('[SyncQueueService] Failed to load queue: $e');
      _queue = [];
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_queue.map((i) => i.toJson()).toList());
      await prefs.setString(_queueKey, encoded);
    } catch (e) {
      print('[SyncQueueService] Failed to save queue: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
