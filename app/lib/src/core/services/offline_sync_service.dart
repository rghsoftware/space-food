/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Type of operation that can be queued for offline sync
enum OfflineOperationType {
  create,
  update,
  delete,
}

/// Queued operation waiting for sync
class QueuedOperation {
  final String id;
  final OfflineOperationType type;
  final String entityType; // 'recipe', 'shopping_item', etc.
  final String entityId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final int retryCount;

  const QueuedOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'entityType': entityType,
        'entityId': entityId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
        id: json['id'] as String,
        type: OfflineOperationType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        data: json['data'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );

  QueuedOperation copyWith({int? retryCount}) => QueuedOperation(
        id: id,
        type: type,
        entityType: entityType,
        entityId: entityId,
        data: data,
        timestamp: timestamp,
        retryCount: retryCount ?? this.retryCount,
      );
}

/// Service for managing offline operation queue and sync
class OfflineSyncService {
  static const _queueKey = 'offline_sync_queue';
  static const _maxRetries = 3;

  final _queue = <QueuedOperation>[];
  final _syncController = StreamController<SyncStatus>.broadcast();
  bool _isSyncing = false;

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncController.stream;

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Initialize service and load queued operations
  Future<void> initialize() async {
    await _loadQueue();
  }

  /// Add operation to queue
  Future<void> queueOperation(QueuedOperation operation) async {
    _queue.add(operation);
    await _saveQueue();
    _syncController.add(SyncStatus(
      isSyncing: false,
      queueSize: _queue.length,
      message: 'Operation queued for sync',
    ));
  }

  /// Sync all queued operations
  Future<void> syncAll() async {
    if (_isSyncing || _queue.isEmpty) return;

    _isSyncing = true;
    _syncController.add(SyncStatus(
      isSyncing: true,
      queueSize: _queue.length,
      message: 'Syncing ${_queue.length} operations...',
    ));

    final operations = List<QueuedOperation>.from(_queue);
    final failed = <QueuedOperation>[];

    for (final operation in operations) {
      try {
        final success = await _syncOperation(operation);
        if (success) {
          _queue.remove(operation);
        } else {
          // Increment retry count
          final updated = operation.copyWith(retryCount: operation.retryCount + 1);
          if (updated.retryCount >= _maxRetries) {
            // Max retries reached, remove from queue
            _queue.remove(operation);
            print('Operation failed after ${_maxRetries} retries: ${operation.id}');
          } else {
            // Update retry count
            final index = _queue.indexOf(operation);
            if (index >= 0) {
              _queue[index] = updated;
            }
            failed.add(updated);
          }
        }
      } catch (e) {
        print('Error syncing operation ${operation.id}: $e');
        failed.add(operation);
      }
    }

    await _saveQueue();

    _isSyncing = false;
    _syncController.add(SyncStatus(
      isSyncing: false,
      queueSize: _queue.length,
      message: failed.isEmpty
          ? 'Sync completed successfully'
          : 'Sync completed with ${failed.length} failures',
      hasErrors: failed.isNotEmpty,
    ));
  }

  /// Sync a single operation (placeholder - actual implementation would call repositories)
  Future<bool> _syncOperation(QueuedOperation operation) async {
    // TODO: Implement actual sync logic by calling appropriate repository methods
    // This is a placeholder that simulates sync
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate 90% success rate
    return DateTime.now().millisecond % 10 != 0;
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    _syncController.add(SyncStatus(
      isSyncing: false,
      queueSize: 0,
      message: 'Queue cleared',
    ));
  }

  /// Load queue from persistent storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _queue.clear();
        _queue.addAll(
          decoded.map((json) => QueuedOperation.fromJson(json as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      print('Error loading offline queue: $e');
    }
  }

  /// Save queue to persistent storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_queue.map((op) => op.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      print('Error saving offline queue: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _syncController.close();
  }
}

/// Sync status information
class SyncStatus {
  final bool isSyncing;
  final int queueSize;
  final String message;
  final bool hasErrors;

  const SyncStatus({
    required this.isSyncing,
    required this.queueSize,
    required this.message,
    this.hasErrors = false,
  });
}
