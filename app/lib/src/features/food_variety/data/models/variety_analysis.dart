// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'food_hyperfixation.dart';

part 'variety_analysis.freezed.dart';
part 'variety_analysis.g.dart';

@freezed
class VarietyAnalysis with _$VarietyAnalysis {
  const factory VarietyAnalysis({
    required int uniqueFoodsLast7Days,
    required int uniqueFoodsLast30Days,
    required List<FoodFrequency> topFoods,
    @Default([]) List<FoodHyperfixation> activeHyperfixations,
    @Default([]) List<String> suggestedRotations,
    required int varietyScore, // 1-10
  }) = _VarietyAnalysis;

  factory VarietyAnalysis.fromJson(Map<String, dynamic> json) =>
      _$VarietyAnalysisFromJson(json);
}

@freezed
class FoodFrequency with _$FoodFrequency {
  const factory FoodFrequency({
    required String foodName,
    required int count,
    required double percentage,
    DateTime? lastEaten,
  }) = _FoodFrequency;

  factory FoodFrequency.fromJson(Map<String, dynamic> json) =>
      _$FoodFrequencyFromJson(json);
}
