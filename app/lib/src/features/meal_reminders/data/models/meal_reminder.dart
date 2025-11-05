/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_reminder.freezed.dart';
part 'meal_reminder.g.dart';

/// Meal reminder model with scheduling and notification settings
@freezed
class MealReminder with _$MealReminder {
  const factory MealReminder({
    required String id,
    required String userId,
    required String name,
    required String scheduledTime, // "HH:MM:SS" format
    @Default(15) int preAlertMinutes,
    @Default(true) bool enabled,
    @Default([0, 1, 2, 3, 4, 5, 6]) List<int> daysOfWeek, // 0=Sunday, 6=Saturday
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MealReminder;

  factory MealReminder.fromJson(Map<String, dynamic> json) =>
      _$MealReminderFromJson(json);
}

/// Request DTO for creating a meal reminder
@freezed
class CreateMealReminderRequest with _$CreateMealReminderRequest {
  const factory CreateMealReminderRequest({
    required String name,
    required String scheduledTime,
    @Default(15) int preAlertMinutes,
    @Default(true) bool enabled,
    @Default([0, 1, 2, 3, 4, 5, 6]) List<int> daysOfWeek,
  }) = _CreateMealReminderRequest;

  factory CreateMealReminderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMealReminderRequestFromJson(json);
}

/// Request DTO for updating a meal reminder
@freezed
class UpdateMealReminderRequest with _$UpdateMealReminderRequest {
  const factory UpdateMealReminderRequest({
    required String name,
    required String scheduledTime,
    required int preAlertMinutes,
    required bool enabled,
    required List<int> daysOfWeek,
  }) = _UpdateMealReminderRequest;

  factory UpdateMealReminderRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMealReminderRequestFromJson(json);
}
