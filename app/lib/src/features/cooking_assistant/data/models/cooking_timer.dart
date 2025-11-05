// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cooking_timer.freezed.dart';
part 'cooking_timer.g.dart';

@freezed
class CookingTimer with _$CookingTimer {
  const factory CookingTimer({
    required String id,
    required String cookingSessionId,
    int? stepIndex,
    required String name,
    required int durationSeconds,
    required int remainingSeconds,
    required String status, // 'running', 'paused', 'completed', 'cancelled'
    required DateTime startedAt,
    DateTime? pausedAt,
    DateTime? resumedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    required int totalPauseDurationSeconds,
    required bool notificationSent,
    DateTime? notificationSentAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CookingTimer;

  factory CookingTimer.fromJson(Map<String, dynamic> json) =>
      _$CookingTimerFromJson(json);
}

// Request DTOs

@freezed
class CreateTimerRequest with _$CreateTimerRequest {
  const factory CreateTimerRequest({
    int? stepIndex,
    required String name,
    required int durationSeconds,
  }) = _CreateTimerRequest;

  factory CreateTimerRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTimerRequestFromJson(json);
}
