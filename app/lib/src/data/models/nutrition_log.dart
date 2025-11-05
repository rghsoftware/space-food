/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipe.dart'; // Import for NutritionInfo

part 'nutrition_log.freezed.dart';
part 'nutrition_log.g.dart';

@freezed
class NutritionLog with _$NutritionLog {
  const factory NutritionLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required DateTime date,
    @JsonKey(name: 'meal_type') required String mealType,
    @JsonKey(name: 'recipe_id') String? recipeId,
    @JsonKey(name: 'food_name') required String foodName,
    required double servings,
    @JsonKey(name: 'nutrition_info') required NutritionInfo nutritionInfo,
    required String notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NutritionLog;

  factory NutritionLog.fromJson(Map<String, dynamic> json) =>
      _$NutritionLogFromJson(json);
}

@freezed
class NutritionLogCreate with _$NutritionLogCreate {
  const factory NutritionLogCreate({
    required DateTime date,
    @JsonKey(name: 'meal_type') required String mealType,
    @JsonKey(name: 'recipe_id') String? recipeId,
    @JsonKey(name: 'food_name') required String foodName,
    required double servings,
    @JsonKey(name: 'nutrition_info') required NutritionInfo nutritionInfo,
    required String notes,
  }) = _NutritionLogCreate;

  factory NutritionLogCreate.fromJson(Map<String, dynamic> json) =>
      _$NutritionLogCreateFromJson(json);
}
