/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_plan.freezed.dart';
part 'meal_plan.g.dart';

@freezed
class MealPlan with _$MealPlan {
  const factory MealPlan({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'household_id') String? householdId,
    required String title,
    required String description,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    required List<PlannedMeal> meals,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _MealPlan;

  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      _$MealPlanFromJson(json);
}

@freezed
class PlannedMeal with _$PlannedMeal {
  const factory PlannedMeal({
    required String id,
    @JsonKey(name: 'meal_plan_id') required String mealPlanId,
    @JsonKey(name: 'recipe_id') required String recipeId,
    required DateTime date,
    @JsonKey(name: 'meal_type') required String mealType,
    required int servings,
    required String notes,
  }) = _PlannedMeal;

  factory PlannedMeal.fromJson(Map<String, dynamic> json) =>
      _$PlannedMealFromJson(json);
}

@freezed
class MealPlanCreate with _$MealPlanCreate {
  const factory MealPlanCreate({
    required String title,
    required String description,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    required List<PlannedMealCreate> meals,
  }) = _MealPlanCreate;

  factory MealPlanCreate.fromJson(Map<String, dynamic> json) =>
      _$MealPlanCreateFromJson(json);
}

@freezed
class PlannedMealCreate with _$PlannedMealCreate {
  const factory PlannedMealCreate({
    @JsonKey(name: 'recipe_id') required String recipeId,
    required DateTime date,
    @JsonKey(name: 'meal_type') required String mealType,
    required int servings,
    required String notes,
  }) = _PlannedMealCreate;

  factory PlannedMealCreate.fromJson(Map<String, dynamic> json) =>
      _$PlannedMealCreateFromJson(json);
}
