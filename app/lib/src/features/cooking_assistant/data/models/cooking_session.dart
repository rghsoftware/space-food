// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cooking_session.freezed.dart';
part 'cooking_session.g.dart';

@freezed
class CookingSession with _$CookingSession {
  const factory CookingSession({
    required String id,
    required String userId,
    required String recipeId,
    String? breakdownId,
    String? mealLogId,
    required String status, // 'active', 'paused', 'completed', 'abandoned'
    required int currentStepIndex,
    required int totalSteps,
    required DateTime startedAt,
    DateTime? pausedAt,
    DateTime? resumedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    required int totalPauseDurationSeconds,
    int? energyLevelAtStart,
    String? notes,
    String? bodyDoublingRoomId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CookingSession;

  factory CookingSession.fromJson(Map<String, dynamic> json) =>
      _$CookingSessionFromJson(json);
}

@freezed
class CookingStepCompletion with _$CookingStepCompletion {
  const factory CookingStepCompletion({
    required String id,
    required String cookingSessionId,
    required int stepIndex,
    required String stepText,
    required DateTime completedAt,
    int? timeTakenSeconds,
    required bool skipped,
    int? difficultyRating,
    String? notes,
    required DateTime createdAt,
  }) = _CookingStepCompletion;

  factory CookingStepCompletion.fromJson(Map<String, dynamic> json) =>
      _$CookingStepCompletionFromJson(json);
}

// Request DTOs

@freezed
class StartCookingSessionRequest with _$StartCookingSessionRequest {
  const factory StartCookingSessionRequest({
    required String recipeId,
    String? breakdownId,
    int? energyLevel,
    String? joinRoomCode,
  }) = _StartCookingSessionRequest;

  factory StartCookingSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$StartCookingSessionRequestFromJson(json);
}

@freezed
class UpdateSessionProgressRequest with _$UpdateSessionProgressRequest {
  const factory UpdateSessionProgressRequest({
    required int currentStepIndex,
    String? notes,
  }) = _UpdateSessionProgressRequest;

  factory UpdateSessionProgressRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSessionProgressRequestFromJson(json);
}

@freezed
class CompleteStepRequest with _$CompleteStepRequest {
  const factory CompleteStepRequest({
    required int stepIndex,
    required String stepText,
    int? timeTakenSeconds,
    @Default(false) bool skipped,
    int? difficultyRating,
    String? notes,
  }) = _CompleteStepRequest;

  factory CompleteStepRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteStepRequestFromJson(json);
}
