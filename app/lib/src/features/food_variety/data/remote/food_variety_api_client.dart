// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/food_hyperfixation.dart';
import '../models/food_chain_suggestion.dart';
import '../models/food_variation.dart';
import '../models/variety_analysis.dart';
import '../models/nutrition_settings.dart';
import '../models/rotation_schedule.dart';

part 'food_variety_api_client.g.dart';

@RestApi()
abstract class FoodVarietyApiClient {
  factory FoodVarietyApiClient(Dio dio, {String baseUrl}) =
      _FoodVarietyApiClient;

  // Hyperfixation endpoints
  @GET('/food-variety/hyperfixations')
  Future<HyperfixationsResponse> getActiveHyperfixations();

  @POST('/food-variety/hyperfixations')
  Future<Map<String, dynamic>> recordHyperfixation(
    @Body() RecordHyperfixationRequest request,
  );

  // Food Chaining endpoints
  @POST('/food-variety/chain-suggestions/generate')
  Future<ChainSuggestionsResponse> generateChainSuggestions(
    @Body() GenerateChainSuggestionsRequest request,
  );

  @GET('/food-variety/chain-suggestions')
  Future<ChainSuggestionsResponse> getUserChainSuggestions({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  @PUT('/food-variety/chain-suggestions/{suggestion_id}/feedback')
  Future<Map<String, dynamic>> recordChainFeedback(
    @Path('suggestion_id') String suggestionId,
    @Body() RecordChainFeedbackRequest request,
  );

  // Variation endpoints
  @GET('/food-variety/variations/{food_name}')
  Future<VariationsResponse> getVariationIdeas(
    @Path('food_name') String foodName,
  );

  // Variety Analysis endpoints
  @GET('/food-variety/analysis')
  Future<VarietyAnalysis> getVarietyAnalysis();

  // Nutrition Settings endpoints
  @GET('/food-variety/nutrition/settings')
  Future<NutritionTrackingSettings> getNutritionSettings();

  @PUT('/food-variety/nutrition/settings')
  Future<NutritionTrackingSettings> updateNutritionSettings(
    @Body() UpdateNutritionSettingsRequest request,
  );

  // Nutrition Insights endpoints
  @GET('/food-variety/nutrition/insights')
  Future<InsightsResponse> getWeeklyInsights();

  @POST('/food-variety/nutrition/insights/generate')
  Future<InsightsResponse> generateWeeklyInsights();

  @PUT('/food-variety/nutrition/insights/{insight_id}/dismiss')
  Future<Map<String, dynamic>> dismissInsight(
    @Path('insight_id') String insightId,
  );

  // Rotation Schedule endpoints
  @POST('/food-variety/rotation-schedules')
  Future<FoodRotationSchedule> createRotationSchedule(
    @Body() CreateRotationScheduleRequest request,
  );

  @GET('/food-variety/rotation-schedules')
  Future<RotationSchedulesResponse> getRotationSchedules();

  @PUT('/food-variety/rotation-schedules/{schedule_id}')
  Future<FoodRotationSchedule> updateRotationSchedule(
    @Path('schedule_id') String scheduleId,
    @Body() UpdateRotationScheduleRequest request,
  );

  @DELETE('/food-variety/rotation-schedules/{schedule_id}')
  Future<Map<String, dynamic>> deleteRotationSchedule(
    @Path('schedule_id') String scheduleId,
  );
}

// Response wrapper classes
class HyperfixationsResponse {
  final List<FoodHyperfixation> hyperfixations;

  HyperfixationsResponse({required this.hyperfixations});

  factory HyperfixationsResponse.fromJson(Map<String, dynamic> json) {
    return HyperfixationsResponse(
      hyperfixations: (json['hyperfixations'] as List)
          .map((e) => FoodHyperfixation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChainSuggestionsResponse {
  final List<FoodChainSuggestion> suggestions;

  ChainSuggestionsResponse({required this.suggestions});

  factory ChainSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return ChainSuggestionsResponse(
      suggestions: (json['suggestions'] as List)
          .map((e) => FoodChainSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VariationsResponse {
  final List<FoodVariation> variations;

  VariationsResponse({required this.variations});

  factory VariationsResponse.fromJson(Map<String, dynamic> json) {
    return VariationsResponse(
      variations: (json['variations'] as List)
          .map((e) => FoodVariation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InsightsResponse {
  final List<NutritionInsight> insights;

  InsightsResponse({required this.insights});

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    return InsightsResponse(
      insights: (json['insights'] as List)
          .map((e) => NutritionInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RotationSchedulesResponse {
  final List<FoodRotationSchedule> schedules;

  RotationSchedulesResponse({required this.schedules});

  factory RotationSchedulesResponse.fromJson(Map<String, dynamic> json) {
    return RotationSchedulesResponse(
      schedules: (json['schedules'] as List)
          .map((e) => FoodRotationSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
