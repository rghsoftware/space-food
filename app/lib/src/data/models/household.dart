/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'household.freezed.dart';
part 'household.g.dart';

@freezed
class Household with _$Household {
  const factory Household({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Household;

  factory Household.fromJson(Map<String, dynamic> json) =>
      _$HouseholdFromJson(json);
}

@freezed
class HouseholdMember with _$HouseholdMember {
  const factory HouseholdMember({
    @JsonKey(name: 'household_id') required String householdId,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _HouseholdMember;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberFromJson(json);
}

@freezed
class HouseholdCreate with _$HouseholdCreate {
  const factory HouseholdCreate({
    required String name,
    required String description,
  }) = _HouseholdCreate;

  factory HouseholdCreate.fromJson(Map<String, dynamic> json) =>
      _$HouseholdCreateFromJson(json);
}

@freezed
class HouseholdInvitation with _$HouseholdInvitation {
  const factory HouseholdInvitation({
    required String email,
    required String role,
  }) = _HouseholdInvitation;

  factory HouseholdInvitation.fromJson(Map<String, dynamic> json) =>
      _$HouseholdInvitationFromJson(json);
}
