/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/kitchen_mode_service.dart';
import '../../core/services/kitchen_timer_service.dart';
import '../../data/models/kitchen_mode.dart';

// Kitchen mode service provider
final kitchenModeServiceProvider = Provider<KitchenModeService>((ref) {
  final service = KitchenModeService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Kitchen timer service provider
final kitchenTimerServiceProvider = Provider<KitchenTimerService>((ref) {
  final service = KitchenTimerService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Kitchen mode state provider
final kitchenModeStateProvider =
    StateNotifierProvider<KitchenModeStateNotifier, KitchenModeState>((ref) {
  return KitchenModeStateNotifier(
    ref.watch(kitchenModeServiceProvider),
    ref.watch(kitchenTimerServiceProvider),
  );
});

// Kitchen mode preferences provider (persisted)
final kitchenModePreferencesProvider =
    StateProvider<KitchenModePreferences>((ref) {
  // TODO: Load from shared preferences or secure storage
  return const KitchenModePreferences();
});

// Active timers stream provider
final activeTimersProvider = StreamProvider<List<KitchenTimer>>((ref) {
  final timerService = ref.watch(kitchenTimerServiceProvider);
  return timerService.timersStream;
});

// Kitchen mode state notifier
class KitchenModeStateNotifier extends StateNotifier<KitchenModeState> {
  final KitchenModeService _kitchenModeService;
  final KitchenTimerService _timerService;

  KitchenModeStateNotifier(this._kitchenModeService, this._timerService)
      : super(const KitchenModeState());

  /// Enable kitchen mode
  Future<void> enableKitchenMode({
    double? brightness,
    bool? keepScreenOn,
    bool? largeText,
    bool? hapticFeedback,
  }) async {
    final newBrightness = brightness ?? 0.8;
    final newKeepScreenOn = keepScreenOn ?? true;

    await _kitchenModeService.enableKitchenMode(brightness: newBrightness);

    state = state.copyWith(
      isEnabled: true,
      brightness: newBrightness,
      keepScreenOn: newKeepScreenOn,
      largeText: largeText ?? state.largeText,
      hapticFeedback: hapticFeedback ?? state.hapticFeedback,
    );
  }

  /// Disable kitchen mode
  Future<void> disableKitchenMode() async {
    await _kitchenModeService.disableKitchenMode();

    state = state.copyWith(
      isEnabled: false,
      keepScreenOn: false,
      currentStep: null,
    );
  }

  /// Toggle kitchen mode
  Future<void> toggleKitchenMode() async {
    if (state.isEnabled) {
      await disableKitchenMode();
    } else {
      await enableKitchenMode();
    }
  }

  /// Update brightness
  Future<void> updateBrightness(double brightness) async {
    await _kitchenModeService.setBrightness(brightness);
    state = state.copyWith(brightness: brightness);
  }

  /// Set current step (for step-by-step cooking)
  void setCurrentStep(int? step) {
    state = state.copyWith(currentStep: step);
  }

  /// Navigate to next step
  void nextStep(int totalSteps) {
    final currentStep = state.currentStep ?? -1;
    if (currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: currentStep + 1);
      if (state.hapticFeedback) {
        _kitchenModeService.hapticFeedback(HapticFeedbackType.selection);
      }
    }
  }

  /// Navigate to previous step
  void previousStep() {
    final currentStep = state.currentStep ?? 0;
    if (currentStep > 0) {
      state = state.copyWith(currentStep: currentStep - 1);
      if (state.hapticFeedback) {
        _kitchenModeService.hapticFeedback(HapticFeedbackType.selection);
      }
    }
  }

  /// Toggle haptic feedback
  void toggleHapticFeedback() {
    state = state.copyWith(hapticFeedback: !state.hapticFeedback);
  }

  /// Toggle large text
  void toggleLargeText() {
    state = state.copyWith(largeText: !state.largeText);
  }

  /// Provide haptic feedback
  Future<void> haptic(HapticFeedbackType type) async {
    if (state.hapticFeedback) {
      await _kitchenModeService.hapticFeedback(type);
    }
  }

  /// Create a new timer
  String createTimer(String label, int durationSeconds) {
    final timerId = _timerService.createTimer(
      label: label,
      durationSeconds: durationSeconds,
    );
    _updateActiveTimers();
    return timerId;
  }

  /// Start a timer
  void startTimer(String id) {
    _timerService.startTimer(id);
    _updateActiveTimers();
    haptic(HapticFeedbackType.medium);
  }

  /// Pause a timer
  void pauseTimer(String id) {
    _timerService.pauseTimer(id);
    _updateActiveTimers();
    haptic(HapticFeedbackType.light);
  }

  /// Resume a timer
  void resumeTimer(String id) {
    _timerService.resumeTimer(id);
    _updateActiveTimers();
    haptic(HapticFeedbackType.medium);
  }

  /// Reset a timer
  void resetTimer(String id) {
    _timerService.resetTimer(id);
    _updateActiveTimers();
    haptic(HapticFeedbackType.light);
  }

  /// Cancel a timer
  void cancelTimer(String id) {
    _timerService.cancelTimer(id);
    _updateActiveTimers();
    haptic(HapticFeedbackType.light);
  }

  /// Add time to a timer
  void addTime(String id, int seconds) {
    _timerService.addTime(id, seconds);
    _updateActiveTimers();
    haptic(HapticFeedbackType.light);
  }

  /// Update active timers in state
  void _updateActiveTimers() {
    state = state.copyWith(
      activeTimers: _timerService.getAllTimers(),
    );
  }
}
