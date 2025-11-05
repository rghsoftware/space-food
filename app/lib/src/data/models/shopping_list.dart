/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list.freezed.dart';
part 'shopping_list.g.dart';

@freezed
class ShoppingListItem with _$ShoppingListItem {
  const factory ShoppingListItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'household_id') String? householdId,
    required String name,
    required double quantity,
    required String unit,
    required String category,
    required String notes,
    required bool completed,
    @JsonKey(name: 'recipe_id') String? recipeId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ShoppingListItem;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      _$ShoppingListItemFromJson(json);
}

@freezed
class ShoppingListItemCreate with _$ShoppingListItemCreate {
  const factory ShoppingListItemCreate({
    required String name,
    required double quantity,
    required String unit,
    required String category,
    required String notes,
    @JsonKey(name: 'recipe_id') String? recipeId,
  }) = _ShoppingListItemCreate;

  factory ShoppingListItemCreate.fromJson(Map<String, dynamic> json) =>
      _$ShoppingListItemCreateFromJson(json);
}
