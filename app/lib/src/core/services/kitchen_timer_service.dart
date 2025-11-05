/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../data/models/kitchen_mode.dart';
import 'notification_service.dart';

/// Service for managing kitchen timers
class KitchenTimerService {
  final _timers = <String, KitchenTimer>{};
  final _timerControllers = <String, StreamController<KitchenTimer>>{};
  final _timerSubscriptions = <String, Timer>{};
  final _uuid = const Uuid();
  final _notificationService = NotificationService();

  /// Stream of all active timers
  Stream<List<KitchenTimer>> get timersStream =>
      Stream.periodic(const Duration(seconds: 1), (_) => getAllTimers());

  /// Create a new timer
  String createTimer({
    required String label,
    required int durationSeconds,
  }) {
    final id = _uuid.v4();
    final timer = KitchenTimer(
      id: id,
      label: label,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: false,
      isPaused: false,
    );

    _timers[id] = timer;
    _timerControllers[id] = StreamController<KitchenTimer>.broadcast();

    return id;
  }

  /// Start a timer
  void startTimer(String id) {
    final timer = _timers[id];
    if (timer == null) return;

    // Update timer state
    _timers[id] = timer.copyWith(
      isRunning: true,
      isPaused: false,
      startedAt: DateTime.now(),
    );

    // Start countdown
    _timerSubscriptions[id] = Timer.periodic(
      const Duration(seconds: 1),
      (periodicTimer) {
        final currentTimer = _timers[id];
        if (currentTimer == null) {
          periodicTimer.cancel();
          return;
        }

        if (currentTimer.remainingSeconds <= 0) {
          // Timer completed
          _onTimerComplete(id);
          periodicTimer.cancel();
          return;
        }

        // Decrement remaining time
        final updatedTimer = currentTimer.copyWith(
          remainingSeconds: currentTimer.remainingSeconds - 1,
        );
        _timers[id] = updatedTimer;
        _timerControllers[id]?.add(updatedTimer);
      },
    );

    _timerControllers[id]?.add(_timers[id]!);
  }

  /// Pause a timer
  void pauseTimer(String id) {
    final timer = _timers[id];
    if (timer == null) return;

    _timerSubscriptions[id]?.cancel();
    _timers[id] = timer.copyWith(
      isRunning: false,
      isPaused: true,
    );
    _timerControllers[id]?.add(_timers[id]!);
  }

  /// Resume a paused timer
  void resumeTimer(String id) {
    final timer = _timers[id];
    if (timer == null || !timer.isPaused) return;

    startTimer(id);
  }

  /// Reset a timer to its original duration
  void resetTimer(String id) {
    final timer = _timers[id];
    if (timer == null) return;

    _timerSubscriptions[id]?.cancel();
    _timers[id] = timer.copyWith(
      remainingSeconds: timer.durationSeconds,
      isRunning: false,
      isPaused: false,
      startedAt: null,
    );
    _timerControllers[id]?.add(_timers[id]!);
  }

  /// Cancel and remove a timer
  void cancelTimer(String id) {
    _timerSubscriptions[id]?.cancel();
    _timerSubscriptions.remove(id);
    _timerControllers[id]?.close();
    _timerControllers.remove(id);
    _timers.remove(id);
  }

  /// Add time to a running timer (in seconds)
  void addTime(String id, int seconds) {
    final timer = _timers[id];
    if (timer == null) return;

    _timers[id] = timer.copyWith(
      remainingSeconds: timer.remainingSeconds + seconds,
      durationSeconds: timer.durationSeconds + seconds,
    );
    _timerControllers[id]?.add(_timers[id]!);
  }

  /// Get a specific timer
  KitchenTimer? getTimer(String id) => _timers[id];

  /// Get stream for a specific timer
  Stream<KitchenTimer>? getTimerStream(String id) =>
      _timerControllers[id]?.stream;

  /// Get all active timers
  List<KitchenTimer> getAllTimers() => _timers.values.toList();

  /// Get count of active timers
  int get activeTimerCount => _timers.length;

  /// Check if any timers are running
  bool get hasRunningTimers =>
      _timers.values.any((timer) => timer.isRunning);

  /// Called when a timer completes
  void _onTimerComplete(String id) {
    final timer = _timers[id];
    if (timer == null) return;

    _timers[id] = timer.copyWith(
      isRunning: false,
      isPaused: false,
      remainingSeconds: 0,
    );
    _timerControllers[id]?.add(_timers[id]!);

    // Show notification
    _notificationService.showTimerComplete(
      timerId: id,
      timerLabel: timer.label,
    );
  }

  /// Dispose all resources
  void dispose() {
    for (final subscription in _timerSubscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _timerControllers.values) {
      controller.close();
    }
    _timerSubscriptions.clear();
    _timerControllers.clear();
    _timers.clear();
  }
}

/// Extension for formatting timer duration
extension KitchenTimerFormatting on KitchenTimer {
  /// Format remaining time as MM:SS or HH:MM:SS
  String get formattedTime {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (durationSeconds == 0) return 0.0;
    return 1.0 - (remainingSeconds / durationSeconds);
  }

  /// Check if timer is about to expire (less than 1 minute remaining)
  bool get isExpiringSoon => remainingSeconds > 0 && remainingSeconds <= 60;

  /// Check if timer has expired
  bool get isExpired => remainingSeconds == 0;
}
