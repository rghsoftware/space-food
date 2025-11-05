// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_variation.freezed.dart';
part 'food_variation.g.dart';

@freezed
class FoodVariation with _$FoodVariation {
  const factory FoodVariation({
    required String id,
    required String baseFoodName,
    required String variationType, // 'sauce', 'topping', 'preparation', 'side'
    required String variationName,
    String? description,
    required int complexity,
    required DateTime createdAt,
  }) = _FoodVariation;

  factory FoodVariation.fromJson(Map<String, dynamic> json) =>
      _$FoodVariationFromJson(json);
}
