// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_hyperfixation.freezed.dart';
part 'food_hyperfixation.g.dart';

@freezed
class FoodHyperfixation with _$FoodHyperfixation {
  const factory FoodHyperfixation({
    required String id,
    required String userId,
    required String foodName,
    required DateTime startedAt,
    required int frequencyCount,
    required double peakFrequencyPerDay,
    required bool isActive,
    DateTime? endedAt,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FoodHyperfixation;

  factory FoodHyperfixation.fromJson(Map<String, dynamic> json) =>
      _$FoodHyperfixationFromJson(json);
}

// Request DTOs

@freezed
class RecordHyperfixationRequest with _$RecordHyperfixationRequest {
  const factory RecordHyperfixationRequest({
    required String foodName,
    String? notes,
  }) = _RecordHyperfixationRequest;

  factory RecordHyperfixationRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordHyperfixationRequestFromJson(json);
}
