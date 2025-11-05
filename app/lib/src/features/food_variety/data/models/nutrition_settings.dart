// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_settings.freezed.dart';
part 'nutrition_settings.g.dart';

@freezed
class NutritionTrackingSettings with _$NutritionTrackingSettings {
  const factory NutritionTrackingSettings({
    required String id,
    required String userId,
    required bool trackingEnabled,
    required bool showCalorieCounts,
    required bool showMacros,
    required bool showMicronutrients,
    @Default([]) List<String> focusNutrients,
    required bool showWeeklySummary,
    required bool showDailySummary,
    required String reminderStyle, // 'gentle', 'none'
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NutritionTrackingSettings;

  factory NutritionTrackingSettings.fromJson(Map<String, dynamic> json) =>
      _$NutritionTrackingSettingsFromJson(json);
}

@freezed
class NutritionInsight with _$NutritionInsight {
  const factory NutritionInsight({
    required String id,
    required String userId,
    required DateTime weekStartDate,
    required String insightType, // 'variety_celebration', 'nutrient_highlight'
    required String message,
    required bool isDismissed,
    required DateTime createdAt,
  }) = _NutritionInsight;

  factory NutritionInsight.fromJson(Map<String, dynamic> json) =>
      _$NutritionInsightFromJson(json);
}

// Request DTOs

@freezed
class UpdateNutritionSettingsRequest with _$UpdateNutritionSettingsRequest {
  const factory UpdateNutritionSettingsRequest({
    bool? trackingEnabled,
    bool? showCalorieCounts,
    bool? showMacros,
    bool? showMicronutrients,
    List<String>? focusNutrients,
    bool? showWeeklySummary,
    bool? showDailySummary,
    String? reminderStyle,
  }) = _UpdateNutritionSettingsRequest;

  factory UpdateNutritionSettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateNutritionSettingsRequestFromJson(json);
}
