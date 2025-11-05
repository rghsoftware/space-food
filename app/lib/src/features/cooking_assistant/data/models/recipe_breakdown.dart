// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_breakdown.freezed.dart';
part 'recipe_breakdown.g.dart';

@freezed
class RecipeBreakdown with _$RecipeBreakdown {
  const factory RecipeBreakdown({
    required String id,
    required String recipeId,
    String? userId,
    required int granularityLevel,
    int? energyLevel,
    required BreakdownData breakdownData,
    required String aiProvider,
    required String aiModel,
    required DateTime generatedAt,
    DateTime? lastUsedAt,
    required int useCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecipeBreakdown;

  factory RecipeBreakdown.fromJson(Map<String, dynamic> json) =>
      _$RecipeBreakdownFromJson(json);
}

@freezed
class BreakdownData with _$BreakdownData {
  const factory BreakdownData({
    required List<BreakdownStep> steps,
    required int totalTimeSeconds,
    required int activeTimeSeconds,
    @Default([]) List<int> prepSteps,
    @Default([]) List<int> cookingSteps,
  }) = _BreakdownData;

  factory BreakdownData.fromJson(Map<String, dynamic> json) =>
      _$BreakdownDataFromJson(json);
}

@freezed
class BreakdownStep with _$BreakdownStep {
  const factory BreakdownStep({
    required int index,
    required String text,
    required int durationSeconds,
    @Default([]) List<BreakdownTimer> timers,
    @Default([]) List<int> dependencies,
    @Default([]) List<String> tips,
    String? imageUrl,
  }) = _BreakdownStep;

  factory BreakdownStep.fromJson(Map<String, dynamic> json) =>
      _$BreakdownStepFromJson(json);
}

@freezed
class BreakdownTimer with _$BreakdownTimer {
  const factory BreakdownTimer({
    required String name,
    required int durationSeconds,
  }) = _BreakdownTimer;

  factory BreakdownTimer.fromJson(Map<String, dynamic> json) =>
      _$BreakdownTimerFromJson(json);
}

// Request DTOs

@freezed
class GenerateBreakdownRequest with _$GenerateBreakdownRequest {
  const factory GenerateBreakdownRequest({
    required String recipeId,
    required int granularityLevel,
    int? energyLevel,
  }) = _GenerateBreakdownRequest;

  factory GenerateBreakdownRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateBreakdownRequestFromJson(json);
}
