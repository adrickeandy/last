/// A single queued write that hasn't been confirmed on Supabase yet.
///
/// Storage philosophy matches [LocalCacheService]: plain-Dart, JSON-encoded,
/// persisted via `shared_preferences`. No new packages, no native plugins -
/// same reasoning as the feed cache (see local_cache_service.dart and the
/// app_links override note in pubspec.yaml).
class SyncQueueItem {
  final String id; // local id - same id used by the optimistic local record
  final String entityType; // 'post' | 'comment' | 'message' | ...
  final String opType; // 'create' | 'update' | 'delete'
  final Map<String, dynamic> payload; // fields needed to perform the write
  final List<String> localImagePaths; // local file paths to upload first, if any
  final String status; // 'pending' | 'syncing' | 'failed'
  final int retryCount;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final String? lastError;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.opType,
    required this.payload,
    this.localImagePaths = const [],
    this.status = 'pending',
    this.retryCount = 0,
    required this.createdAt,
    required this.nextAttemptAt,
    this.lastError,
  });

  SyncQueueItem copyWith({
    String? status,
    int? retryCount,
    DateTime? nextAttemptAt,
    String? lastError,
  }) {
    return SyncQueueItem(
      id: id,
      entityType: entityType,
      opType: opType,
      payload: payload,
      localImagePaths: localImagePaths,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'op_type': opType,
        'payload': payload,
        'local_image_paths': localImagePaths,
        'status': status,
        'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
        'next_attempt_at': nextAttemptAt.toIso8601String(),
        'last_error': lastError,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['local_image_paths'];
    return SyncQueueItem(
      id: json['id'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      opType: json['op_type'] as String? ?? 'create',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      localImagePaths:
          rawPaths is List ? rawPaths.map((e) => e.toString()).toList() : [],
      status: json['status'] as String? ?? 'pending',
      retryCount: json['retry_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      nextAttemptAt:
          DateTime.tryParse(json['next_attempt_at'] as String? ?? '') ?? DateTime.now(),
      lastError: json['last_error'] as String?,
    );
  }
}
