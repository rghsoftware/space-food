// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_chain_suggestion.freezed.dart';
part 'food_chain_suggestion.g.dart';

@freezed
class FoodChainSuggestion with _$FoodChainSuggestion {
  const factory FoodChainSuggestion({
    required String id,
    required String userId,
    required String currentFoodName,
    required String suggestedFoodName,
    required double similarityScore,
    required String reasoning,
    required bool wasTried,
    bool? wasLiked,
    DateTime? triedAt,
    String? feedback,
    required DateTime createdAt,
  }) = _FoodChainSuggestion;

  factory FoodChainSuggestion.fromJson(Map<String, dynamic> json) =>
      _$FoodChainSuggestionFromJson(json);
}

// Request DTOs

@freezed
class GenerateChainSuggestionsRequest with _$GenerateChainSuggestionsRequest {
  const factory GenerateChainSuggestionsRequest({
    required String foodName,
    @Default(5) int count,
  }) = _GenerateChainSuggestionsRequest;

  factory GenerateChainSuggestionsRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateChainSuggestionsRequestFromJson(json);
}

@freezed
class RecordChainFeedbackRequest with _$RecordChainFeedbackRequest {
  const factory RecordChainFeedbackRequest({
    required bool wasLiked,
    String? feedback,
  }) = _RecordChainFeedbackRequest;

  factory RecordChainFeedbackRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordChainFeedbackRequestFromJson(json);
}
