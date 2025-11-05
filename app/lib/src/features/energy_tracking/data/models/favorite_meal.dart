/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_meal.freezed.dart';
part 'favorite_meal.g.dart';

/// Favorite meal model with energy associations
@freezed
class FavoriteMeal with _$FavoriteMeal {
  const factory FavoriteMeal({
    required String id,
    required String userId,
    String? recipeId,
    required String mealName,
    int? energyLevel, // 1-5
    String? typicalTimeOfDay, // morning, afternoon, evening, night
    @Default(0) int frequencyScore,
    DateTime? lastEaten,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FavoriteMeal;

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) =>
      _$FavoriteMealFromJson(json);
}

/// Request DTO for saving a favorite meal
@freezed
class SaveFavoriteMealRequest with _$SaveFavoriteMealRequest {
  const factory SaveFavoriteMealRequest({
    String? recipeId,
    required String mealName,
    int? energyLevel,
    String? typicalTimeOfDay,
    String? notes,
  }) = _SaveFavoriteMealRequest;

  factory SaveFavoriteMealRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveFavoriteMealRequestFromJson(json);
}

/// Request DTO for updating a favorite meal
@freezed
class UpdateFavoriteMealRequest with _$UpdateFavoriteMealRequest {
  const factory UpdateFavoriteMealRequest({
    required String mealName,
    int? energyLevel,
    String? typicalTimeOfDay,
    String? notes,
  }) = _UpdateFavoriteMealRequest;

  factory UpdateFavoriteMealRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateFavoriteMealRequestFromJson(json);
}

/// Energy-based meal recommendations
@freezed
class EnergyBasedRecommendation with _$EnergyBasedRecommendation {
  const factory EnergyBasedRecommendation({
    required List<FavoriteMeal> meals,
    required int currentEnergy,
    required String timeOfDay,
    required String reasoning,
  }) = _EnergyBasedRecommendation;

  factory EnergyBasedRecommendation.fromJson(Map<String, dynamic> json) =>
      _$EnergyBasedRecommendationFromJson(json);
}

/// Recipe with energy information
@freezed
class RecipeWithEnergy with _$RecipeWithEnergy {
  const factory RecipeWithEnergy({
    required String id,
    required String name,
    int? energyLevel,
    int? preparationTimeMinutes,
    int? activeTimeMinutes,
  }) = _RecipeWithEnergy;

  factory RecipeWithEnergy.fromJson(Map<String, dynamic> json) =>
      _$RecipeWithEnergyFromJson(json);
}
