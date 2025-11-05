/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/ai_api.dart';
import '../models/ai_models.dart';

class AiRepository {
  final AiApi _aiApi;

  AiRepository(this._aiApi);

  Future<Either<ApiException, RecipeSuggestionResponse>> suggestRecipes(
    RecipeSuggestionRequest request,
  ) async {
    try {
      final response = await _aiApi.suggestRecipes(request);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, RecipeVariationResponse>> createRecipeVariation(
    RecipeVariationRequest request,
  ) async {
    try {
      final response = await _aiApi.createRecipeVariation(request);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, NutritionAnalysisResponse>> analyzeNutrition(
    NutritionAnalysisRequest request,
  ) async {
    try {
      final response = await _aiApi.analyzeNutrition(request);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, IngredientSubstitutionResponse>>
      getSubstitutions(
    IngredientSubstitutionRequest request,
  ) async {
    try {
      final response = await _aiApi.getSubstitutions(request);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, MealPlanGenerationResponse>> generateMealPlan(
    MealPlanGenerationRequest request,
  ) async {
    try {
      final response = await _aiApi.generateMealPlan(request);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException.timeout('Request timeout');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException.network('No internet connection');
    }

    final statusCode = error.response?.statusCode;
    final message =
        error.response?.data['error'] ?? error.message ?? 'Unknown error';

    if (statusCode != null) {
      return ApiException.fromStatusCode(statusCode, message);
    }

    return ApiException.unknown(message);
  }
}
