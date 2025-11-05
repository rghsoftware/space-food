/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'eating_timeline.freezed.dart';
part 'eating_timeline.g.dart';

/// Daily eating timeline entry showing meals logged
@freezed
class EatingTimeline with _$EatingTimeline {
  const factory EatingTimeline({
    required DateTime date,
    required int mealCount,
    required int snackCount,
    required int totalCount,
    required bool metGoals,
    int? streak, // Optional: only included if show_streak is true
  }) = _EatingTimeline;

  factory EatingTimeline.fromJson(Map<String, dynamic> json) =>
      _$EatingTimelineFromJson(json);
}

/// User settings for eating timeline display
@freezed
class EatingTimelineSettings with _$EatingTimelineSettings {
  const factory EatingTimelineSettings({
    required String userId,
    @Default(3) int dailyMealGoal,
    @Default(2) int dailySnackGoal,
    @Default(true) bool showStreak,
    @Default(false) bool showMissedMeals, // Shame-free default
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EatingTimelineSettings;

  factory EatingTimelineSettings.fromJson(Map<String, dynamic> json) =>
      _$EatingTimelineSettingsFromJson(json);
}

/// Request DTO for updating timeline settings
@freezed
class UpdateTimelineSettingsRequest with _$UpdateTimelineSettingsRequest {
  const factory UpdateTimelineSettingsRequest({
    required int dailyMealGoal,
    required int dailySnackGoal,
    required bool showStreak,
    required bool showMissedMeals,
  }) = _UpdateTimelineSettingsRequest;

  factory UpdateTimelineSettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTimelineSettingsRequestFromJson(json);
}

/// Response for timeline endpoint with settings and data
@freezed
class TimelineResponse with _$TimelineResponse {
  const factory TimelineResponse({
    required EatingTimelineSettings settings,
    required List<EatingTimeline> timeline,
  }) = _TimelineResponse;

  factory TimelineResponse.fromJson(Map<String, dynamic> json) =>
      _$TimelineResponseFromJson(json);
}
