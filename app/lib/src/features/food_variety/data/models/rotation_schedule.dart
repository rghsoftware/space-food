// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rotation_schedule.freezed.dart';
part 'rotation_schedule.g.dart';

@freezed
class FoodRotationSchedule with _$FoodRotationSchedule {
  const factory FoodRotationSchedule({
    required String id,
    required String userId,
    required String scheduleName,
    required int rotationDays,
    required List<RotationFood> foods,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FoodRotationSchedule;

  factory FoodRotationSchedule.fromJson(Map<String, dynamic> json) =>
      _$FoodRotationScheduleFromJson(json);
}

@freezed
class RotationFood with _$RotationFood {
  const factory RotationFood({
    required String foodName,
    String? portionSize,
    String? notes,
  }) = _RotationFood;

  factory RotationFood.fromJson(Map<String, dynamic> json) =>
      _$RotationFoodFromJson(json);
}

// Request DTOs

@freezed
class CreateRotationScheduleRequest with _$CreateRotationScheduleRequest {
  const factory CreateRotationScheduleRequest({
    required String scheduleName,
    required int rotationDays,
    required List<RotationFood> foods,
  }) = _CreateRotationScheduleRequest;

  factory CreateRotationScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRotationScheduleRequestFromJson(json);
}

@freezed
class UpdateRotationScheduleRequest with _$UpdateRotationScheduleRequest {
  const factory UpdateRotationScheduleRequest({
    String? scheduleName,
    int? rotationDays,
    List<RotationFood>? foods,
    bool? isActive,
  }) = _UpdateRotationScheduleRequest;

  factory UpdateRotationScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRotationScheduleRequestFromJson(json);
}
