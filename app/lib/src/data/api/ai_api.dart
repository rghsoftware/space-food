/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/ai_models.dart';

part 'ai_api.g.dart';

@RestApi()
abstract class AiApi {
  factory AiApi(Dio dio, {String baseUrl}) = _AiApi;

  @POST('/ai/recipes/suggest')
  Future<RecipeSuggestionResponse> suggestRecipes(
    @Body() RecipeSuggestionRequest request,
  );

  @POST('/ai/recipes/variation')
  Future<RecipeVariationResponse> createRecipeVariation(
    @Body() RecipeVariationRequest request,
  );

  @POST('/ai/recipes/analyze-nutrition')
  Future<NutritionAnalysisResponse> analyzeNutrition(
    @Body() NutritionAnalysisRequest request,
  );

  @POST('/ai/recipes/substitutions')
  Future<IngredientSubstitutionResponse> getSubstitutions(
    @Body() IngredientSubstitutionRequest request,
  );

  @POST('/ai/meal-planning/generate')
  Future<MealPlanGenerationResponse> generateMealPlan(
    @Body() MealPlanGenerationRequest request,
  );
}
