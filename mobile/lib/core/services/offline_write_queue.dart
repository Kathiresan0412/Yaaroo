import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

/// Represents a single queued write operation that persists across app restarts.
class QueuedWrite {
  QueuedWrite({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.operationType,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Unique identifier for this queued operation.
  final String id;

  /// Firestore collection path.
  final String collection;

  /// Target document ID (null for add operations).
  final String? documentId;

  /// The data to write (serialized as JSON-compatible map).
  final Map<String, dynamic> data;

  /// Type of write operation: 'set', 'update', or 'delete'.
  final String operationType;

  /// When this operation was first queued.
  final DateTime createdAt;

  /// Number of retry attempts made.
  int retryCount;

  /// Maximum retry attempts before discarding.
  static const int maxRetries = 5;

  /// Whether this operation has exceeded max retries.
  bool get isExhausted => retryCount >= maxRetries;

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'operationType': operationType,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedWrite.fromJson(Map<String, dynamic> json) => QueuedWrite(
        id: json['id'] as String,
        collection: json['collection'] as String,
        documentId: json['documentId'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map),
        operationType: json['operationType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// Result of processing the write queue.
class WriteQueueResult {
  const WriteQueueResult({
    required this.succeeded,
    required this.failed,
    required this.discarded,
  });

  /// Operations that completed successfully.
  final int succeeded;

  /// Operations that failed but can be retried.
  final int failed;

  /// Operations discarded after max retries.
  final int discarded;
}

/// Service that manages a persistent queue of write operations for offline use.
///
/// When the device is offline, writes are queued locally using SharedPreferences.
/// When connectivity is restored, queued writes are retried automatically.
/// Each operation is retried up to 5 times before being discarded with an error.
///
/// Sync is triggered within 30 seconds of reconnection.
class OfflineWriteQueueService {
  OfflineWriteQueueService({
    required ConnectivityService connectivityService,
    FirebaseFirestore? firestore,
  })  : _connectivityService = connectivityService,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _listenForReconnection();
  }

  final ConnectivityService _connectivityService;
  final FirebaseFirestore _firestore;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;

  static const String _storageKey = 'offline_write_queue';

  /// Callback invoked when an operation is discarded after max retries.
  /// The UI layer should listen to this to show error messages.
  final _discardController = StreamController<QueuedWrite>.broadcast();
  Stream<QueuedWrite> get onOperationDiscarded => _discardController.stream;

  /// The current pending writes (in-memory cache loaded from persistence).
  List<QueuedWrite> _queue = [];

  /// Whether the queue is currently being processed.
  bool _isProcessing = false;

  /// Number of pending writes in the queue.
  int get pendingCount => _queue.length;

  /// Whether there are pending writes.
  bool get hasPendingWrites => _queue.isNotEmpty;

  /// Enqueues a write operation for later execution.
  ///
  /// If the device is online, attempts the write immediately.
  /// If the write fails or the device is offline, the operation is persisted.
  Future<bool> enqueue({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    required String operationType,
  }) async {
    // If online, try to execute immediately
    if (_connectivityService.isOnline) {
      try {
        await _executeWrite(
          collection: collection,
          documentId: documentId,
          data: data,
          operationType: operationType,
        );
        return true;
      } catch (e) {
        debugPrint('Immediate write failed, queueing: $e');
      }
    }

    // Queue the operation
    final write = QueuedWrite(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      collection: collection,
      documentId: documentId,
      data: data,
      operationType: operationType,
      createdAt: DateTime.now(),
    );

    _queue.add(write);
    await _persistQueue();
    return false;
  }

  /// Loads the queue from persistent storage.
  Future<void> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      _queue = [];
      return;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _queue = jsonList
          .map((item) =>
              QueuedWrite.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Failed to load write queue: $e');
      _queue = [];
    }
  }

  /// Persists the current queue to SharedPreferences.
  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_queue.map((w) => w.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Listens for connectivity changes and triggers sync on reconnection.
  void _listenForReconnection() {
    _connectivitySubscription =
        _connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online && _queue.isNotEmpty) {
        // Sync within 30 seconds of reconnection (use short delay to debounce)
        _syncTimer?.cancel();
        _syncTimer = Timer(const Duration(seconds: 2), () {
          processQueue();
        });
      }
    });
  }

  /// Processes all pending writes in the queue.
  ///
  /// Returns a [WriteQueueResult] summarizing the outcome.
  /// Syncs within 30 seconds of reconnection per requirement 20.3.
  Future<WriteQueueResult> processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return const WriteQueueResult(succeeded: 0, failed: 0, discarded: 0);
    }

    _isProcessing = true;
    int succeeded = 0;
    int failed = 0;
    int discarded = 0;

    final toProcess = List<QueuedWrite>.from(_queue);

    for (final write in toProcess) {
      if (!_connectivityService.isOnline) {
        // Lost connection during processing, stop
        break;
      }

      try {
        await _executeWrite(
          collection: write.collection,
          documentId: write.documentId,
          data: write.data,
          operationType: write.operationType,
        );
        _queue.remove(write);
        succeeded++;
      } catch (e) {
        write.retryCount++;
        if (write.isExhausted) {
          _queue.remove(write);
          _discardController.add(write);
          discarded++;
          debugPrint(
            'Discarded write after ${QueuedWrite.maxRetries} retries: '
            '${write.collection}/${write.documentId}',
          );
        } else {
          failed++;
          debugPrint(
            'Write retry ${write.retryCount}/${QueuedWrite.maxRetries}: '
            '${write.collection}/${write.documentId}',
          );
        }
      }
    }

    await _persistQueue();
    _isProcessing = false;

    return WriteQueueResult(
      succeeded: succeeded,
      failed: failed,
      discarded: discarded,
    );
  }

  /// Executes a single write operation against Firestore.
  Future<void> _executeWrite({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    required String operationType,
  }) async {
    final collectionRef = _firestore.collection(collection);

    switch (operationType) {
      case 'set':
        if (documentId != null) {
          await collectionRef.doc(documentId).set(data);
        } else {
          await collectionRef.add(data);
        }
      case 'update':
        if (documentId == null) {
          throw ArgumentError('documentId required for update operations');
        }
        await collectionRef.doc(documentId).update(data);
      case 'delete':
        if (documentId == null) {
          throw ArgumentError('documentId required for delete operations');
        }
        await collectionRef.doc(documentId).delete();
      default:
        throw ArgumentError('Unknown operation type: $operationType');
    }
  }

  /// Clears all pending writes from the queue.
  Future<void> clearQueue() async {
    _queue.clear();
    await _persistQueue();
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _discardController.close();
  }
}

/// Provider for the offline write queue service.
final offlineWriteQueueProvider = Provider<OfflineWriteQueueService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final service = OfflineWriteQueueService(
    connectivityService: connectivityService,
  );
  // Load persisted queue on creation
  service.loadQueue();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider that exposes the stream of discarded operations for UI display.
final discardedWriteProvider = StreamProvider<QueuedWrite>((ref) {
  final queue = ref.watch(offlineWriteQueueProvider);
  return queue.onOperationDiscarded;
});
