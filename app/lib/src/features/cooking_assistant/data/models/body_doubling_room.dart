// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_doubling_room.freezed.dart';
part 'body_doubling_room.g.dart';

@freezed
class BodyDoublingRoom with _$BodyDoublingRoom {
  const factory BodyDoublingRoom({
    required String id,
    required String createdBy,
    required String roomName,
    required String roomCode,
    String? description,
    required int maxParticipants,
    required bool isPublic,
    required String status, // 'active', 'ended'
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? endedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BodyDoublingRoom;

  factory BodyDoublingRoom.fromJson(Map<String, dynamic> json) =>
      _$BodyDoublingRoomFromJson(json);
}

@freezed
class BodyDoublingParticipant with _$BodyDoublingParticipant {
  const factory BodyDoublingParticipant({
    required String id,
    required String roomId,
    required String userId,
    String? cookingSessionId,
    required DateTime joinedAt,
    DateTime? leftAt,
    required bool isActive,
    String? recipeName,
    String? currentStep,
    int? energyLevel,
    required DateTime lastActivityAt,
    required int messageCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BodyDoublingParticipant;

  factory BodyDoublingParticipant.fromJson(Map<String, dynamic> json) =>
      _$BodyDoublingParticipantFromJson(json);
}

// Request DTOs

@freezed
class CreateBodyDoublingRoomRequest with _$CreateBodyDoublingRoomRequest {
  const factory CreateBodyDoublingRoomRequest({
    required String roomName,
    String? description,
    @Default(10) int maxParticipants,
    @Default(false) bool isPublic,
    String? password,
    DateTime? scheduledStartTime,
  }) = _CreateBodyDoublingRoomRequest;

  factory CreateBodyDoublingRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBodyDoublingRoomRequestFromJson(json);
}

@freezed
class JoinBodyDoublingRoomRequest with _$JoinBodyDoublingRoomRequest {
  const factory JoinBodyDoublingRoomRequest({
    required String roomCode,
    String? password,
    String? cookingSessionId,
    String? recipeName,
  }) = _JoinBodyDoublingRoomRequest;

  factory JoinBodyDoublingRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinBodyDoublingRoomRequestFromJson(json);
}

@freezed
class UpdateParticipantActivityRequest with _$UpdateParticipantActivityRequest {
  const factory UpdateParticipantActivityRequest({
    String? currentStep,
    int? energyLevel,
  }) = _UpdateParticipantActivityRequest;

  factory UpdateParticipantActivityRequest.fromJson(
          Map<String, dynamic> json) =>
      _$UpdateParticipantActivityRequestFromJson(json);
}
