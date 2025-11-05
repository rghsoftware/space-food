/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'kitchen_mode.freezed.dart';
part 'kitchen_mode.g.dart';

/// Kitchen mode state
@freezed
class KitchenModeState with _$KitchenModeState {
  const factory KitchenModeState({
    @Default(false) bool isEnabled,
    @Default(0.8) double brightness,
    @Default(false) bool keepScreenOn,
    @Default(false) bool largeText,
    @Default(false) bool hapticFeedback,
    @JsonKey(name: 'current_step') int? currentStep,
    @JsonKey(name: 'active_timers') @Default([]) List<KitchenTimer> activeTimers,
  }) = _KitchenModeState;

  factory KitchenModeState.fromJson(Map<String, dynamic> json) =>
      _$KitchenModeStateFromJson(json);
}

/// Kitchen timer model
@freezed
class KitchenTimer with _$KitchenTimer {
  const factory KitchenTimer({
    required String id,
    required String label,
    @JsonKey(name: 'duration_seconds') required int durationSeconds,
    @JsonKey(name: 'remaining_seconds') required int remainingSeconds,
    @Default(false) bool isRunning,
    @Default(false) bool isPaused,
    @JsonKey(name: 'started_at') DateTime? startedAt,
  }) = _KitchenTimer;

  factory KitchenTimer.fromJson(Map<String, dynamic> json) =>
      _$KitchenTimerFromJson(json);
}

/// Kitchen mode preferences (persisted)
@freezed
class KitchenModePreferences with _$KitchenModePreferences {
  const factory KitchenModePreferences({
    @Default(0.8) double preferredBrightness,
    @Default(true) bool keepScreenOn,
    @Default(true) bool largeText,
    @Default(true) bool hapticFeedback,
    @Default(true) bool showTimers,
    @Default(true) bool showIngredients,
    @Default(false) bool autoAdvanceSteps,
  }) = _KitchenModePreferences;

  factory KitchenModePreferences.fromJson(Map<String, dynamic> json) =>
      _$KitchenModePreferencesFromJson(json);
}
