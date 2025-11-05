/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pantry.freezed.dart';
part 'pantry.g.dart';

@freezed
class PantryItem with _$PantryItem {
  const factory PantryItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'household_id') String? householdId,
    required String name,
    required double quantity,
    required String unit,
    required String category,
    required String location,
    @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    required String notes,
    required String barcode,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _PantryItem;

  factory PantryItem.fromJson(Map<String, dynamic> json) =>
      _$PantryItemFromJson(json);
}

@freezed
class PantryItemCreate with _$PantryItemCreate {
  const factory PantryItemCreate({
    required String name,
    required double quantity,
    required String unit,
    required String category,
    required String location,
    @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    required String notes,
    required String barcode,
  }) = _PantryItemCreate;

  factory PantryItemCreate.fromJson(Map<String, dynamic> json) =>
      _$PantryItemCreateFromJson(json);
}
