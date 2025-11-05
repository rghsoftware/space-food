/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'energy_snapshot.freezed.dart';
part 'energy_snapshot.g.dart';

/// Energy snapshot model representing a single energy level recording
@freezed
class EnergySnapshot with _$EnergySnapshot {
  const factory EnergySnapshot({
    required String id,
    required String userId,
    required DateTime recordedAt,
    required int energyLevel, // 1-5
    required String timeOfDay, // morning, afternoon, evening, night
    required int dayOfWeek, // 0=Sunday, 6=Saturday
    String? context, // meal_log, manual_entry, cooking_session
    required DateTime createdAt,
  }) = _EnergySnapshot;

  factory EnergySnapshot.fromJson(Map<String, dynamic> json) =>
      _$EnergySnapshotFromJson(json);
}

/// Request DTO for recording energy level
@freezed
class RecordEnergyRequest with _$RecordEnergyRequest {
  const factory RecordEnergyRequest({
    required int energyLevel,
    String? context,
  }) = _RecordEnergyRequest;

  factory RecordEnergyRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordEnergyRequestFromJson(json);
}

/// Response with energy snapshots history
@freezed
class EnergySnapshotsResponse with _$EnergySnapshotsResponse {
  const factory EnergySnapshotsResponse({
    required List<EnergySnapshot> snapshots,
    required DateTime startDate,
    required DateTime endDate,
  }) = _EnergySnapshotsResponse;

  factory EnergySnapshotsResponse.fromJson(Map<String, dynamic> json) =>
      _$EnergySnapshotsResponseFromJson(json);
}

/// User energy pattern (learned over time)
@freezed
class UserEnergyPattern with _$UserEnergyPattern {
  const factory UserEnergyPattern({
    required String id,
    required String userId,
    required String timeOfDay,
    required int dayOfWeek,
    required int typicalEnergyLevel,
    required int sampleCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserEnergyPattern;

  factory UserEnergyPattern.fromJson(Map<String, dynamic> json) =>
      _$UserEnergyPatternFromJson(json);
}
