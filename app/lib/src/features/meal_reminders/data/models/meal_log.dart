/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_log.freezed.dart';
part 'meal_log.g.dart';

/// Meal log entry recording when a user ate
@freezed
class MealLog with _$MealLog {
  const factory MealLog({
    required String id,
    required String userId,
    String? reminderId, // Optional: null if manually logged
    required DateTime loggedAt,
    DateTime? scheduledFor, // Optional: when meal was supposed to be eaten
    String? notes,
    int? energyLevel, // 1-5 scale, optional
    required DateTime createdAt,
  }) = _MealLog;

  factory MealLog.fromJson(Map<String, dynamic> json) =>
      _$MealLogFromJson(json);
}

/// Request DTO for logging a meal
@freezed
class LogMealRequest with _$LogMealRequest {
  const factory LogMealRequest({
    String? reminderId, // Optional: associate with reminder
    DateTime? loggedAt, // Optional: defaults to now on backend
    String? notes,
    int? energyLevel, // 1-5 scale
  }) = _LogMealRequest;

  factory LogMealRequest.fromJson(Map<String, dynamic> json) =>
      _$LogMealRequestFromJson(json);
}

/// Response with meal log and optional scheduled time
@freezed
class LogMealResponse with _$LogMealResponse {
  const factory LogMealResponse({
    required String id,
    required String userId,
    String? reminderId,
    required DateTime loggedAt,
    DateTime? scheduledFor,
    String? notes,
    int? energyLevel,
    required DateTime createdAt,
  }) = _LogMealResponse;

  factory LogMealResponse.fromJson(Map<String, dynamic> json) =>
      _$LogMealResponseFromJson(json);
}
