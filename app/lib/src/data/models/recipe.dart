/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'household_id') String? householdId,
    required String title,
    required String description,
    required String instructions,
    @JsonKey(name: 'prep_time') required int prepTime,
    @JsonKey(name: 'cook_time') required int cookTime,
    required int servings,
    required String difficulty,
    @JsonKey(name: 'image_url') String? imageUrl,
    required List<String> categories,
    required List<String> tags,
    required List<Ingredient> ingredients,
    @JsonKey(name: 'nutrition_info') NutritionInfo? nutritionInfo,
    String? source,
    @JsonKey(name: 'source_url') String? sourceUrl,
    required double rating,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,
    @JsonKey(name: 'recipe_id') required String recipeId,
    required String name,
    required double quantity,
    required String unit,
    String? notes,
    required bool optional,
    required int order,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

@freezed
class NutritionInfo with _$NutritionInfo {
  const factory NutritionInfo({
    required double calories,
    required double protein,
    required double carbohydrates,
    required double fat,
    required double fiber,
    required double sugar,
    required double sodium,
  }) = _NutritionInfo;

  factory NutritionInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionInfoFromJson(json);
}

@freezed
class RecipeCreate with _$RecipeCreate {
  const factory RecipeCreate({
    required String title,
    required String description,
    required String instructions,
    @JsonKey(name: 'prep_time') required int prepTime,
    @JsonKey(name: 'cook_time') required int cookTime,
    required int servings,
    required String difficulty,
    required List<String> categories,
    required List<String> tags,
    required List<IngredientCreate> ingredients,
    @JsonKey(name: 'nutrition_info') NutritionInfo? nutritionInfo,
    String? source,
    @JsonKey(name: 'source_url') String? sourceUrl,
  }) = _RecipeCreate;

  factory RecipeCreate.fromJson(Map<String, dynamic> json) =>
      _$RecipeCreateFromJson(json);
}

@freezed
class IngredientCreate with _$IngredientCreate {
  const factory IngredientCreate({
    required String name,
    required double quantity,
    required String unit,
    String? notes,
    required bool optional,
    required int order,
  }) = _IngredientCreate;

  factory IngredientCreate.fromJson(Map<String, dynamic> json) =>
      _$IngredientCreateFromJson(json);
}
