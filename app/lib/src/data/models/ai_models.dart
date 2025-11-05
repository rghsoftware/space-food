/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipe.dart';
import 'meal_plan.dart';

part 'ai_models.freezed.dart';
part 'ai_models.g.dart';

// Recipe Suggestion
@freezed
class RecipeSuggestionRequest with _$RecipeSuggestionRequest {
  const factory RecipeSuggestionRequest({
    required List<String> ingredients,
    @JsonKey(name: 'dietary_restrictions') List<String>? dietaryRestrictions,
    String? cuisine,
    @JsonKey(name: 'max_prep_time') int? maxPrepTime,
    int? servings,
  }) = _RecipeSuggestionRequest;

  factory RecipeSuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$RecipeSuggestionRequestFromJson(json);
}

@freezed
class RecipeSuggestionResponse with _$RecipeSuggestionResponse {
  const factory RecipeSuggestionResponse({
    required List<Recipe> suggestions,
  }) = _RecipeSuggestionResponse;

  factory RecipeSuggestionResponse.fromJson(Map<String, dynamic> json) =>
      _$RecipeSuggestionResponseFromJson(json);
}

// Recipe Variation
@freezed
class RecipeVariationRequest with _$RecipeVariationRequest {
  const factory RecipeVariationRequest({
    @JsonKey(name: 'recipe_id') required String recipeId,
    @JsonKey(name: 'variation_type') required String variationType,
    @JsonKey(name: 'dietary_restrictions') List<String>? dietaryRestrictions,
  }) = _RecipeVariationRequest;

  factory RecipeVariationRequest.fromJson(Map<String, dynamic> json) =>
      _$RecipeVariationRequestFromJson(json);
}

@freezed
class RecipeVariationResponse with _$RecipeVariationResponse {
  const factory RecipeVariationResponse({
    required Recipe variation,
  }) = _RecipeVariationResponse;

  factory RecipeVariationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecipeVariationResponseFromJson(json);
}

// Nutrition Analysis
@freezed
class NutritionAnalysisRequest with _$NutritionAnalysisRequest {
  const factory NutritionAnalysisRequest({
    required String text,
  }) = _NutritionAnalysisRequest;

  factory NutritionAnalysisRequest.fromJson(Map<String, dynamic> json) =>
      _$NutritionAnalysisRequestFromJson(json);
}

@freezed
class NutritionAnalysisResponse with _$NutritionAnalysisResponse {
  const factory NutritionAnalysisResponse({
    @JsonKey(name: 'nutrition_info') required NutritionInfo nutritionInfo,
    required List<String> ingredients,
  }) = _NutritionAnalysisResponse;

  factory NutritionAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$NutritionAnalysisResponseFromJson(json);
}

// Ingredient Substitutions
@freezed
class IngredientSubstitutionRequest with _$IngredientSubstitutionRequest {
  const factory IngredientSubstitutionRequest({
    required String ingredient,
    String? reason,
  }) = _IngredientSubstitutionRequest;

  factory IngredientSubstitutionRequest.fromJson(Map<String, dynamic> json) =>
      _$IngredientSubstitutionRequestFromJson(json);
}

@freezed
class IngredientSubstitutionResponse with _$IngredientSubstitutionResponse {
  const factory IngredientSubstitutionResponse({
    required String ingredient,
    required List<Substitution> substitutions,
  }) = _IngredientSubstitutionResponse;

  factory IngredientSubstitutionResponse.fromJson(Map<String, dynamic> json) =>
      _$IngredientSubstitutionResponseFromJson(json);
}

@freezed
class Substitution with _$Substitution {
  const factory Substitution({
    required String ingredient,
    required String ratio,
    required String notes,
  }) = _Substitution;

  factory Substitution.fromJson(Map<String, dynamic> json) =>
      _$SubstitutionFromJson(json);
}

// Meal Plan Generation
@freezed
class MealPlanGenerationRequest with _$MealPlanGenerationRequest {
  const factory MealPlanGenerationRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'dietary_restrictions') List<String>? dietaryRestrictions,
    @JsonKey(name: 'calorie_target') int? calorieTarget,
    int? servings,
    List<String>? preferences,
  }) = _MealPlanGenerationRequest;

  factory MealPlanGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$MealPlanGenerationRequestFromJson(json);
}

@freezed
class MealPlanGenerationResponse with _$MealPlanGenerationResponse {
  const factory MealPlanGenerationResponse({
    @JsonKey(name: 'meal_plan') required MealPlan mealPlan,
  }) = _MealPlanGenerationResponse;

  factory MealPlanGenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$MealPlanGenerationResponseFromJson(json);
}
