/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/recipe_api.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final RecipeApi _recipeApi;

  RecipeRepository(this._recipeApi);

  Future<Either<ApiException, List<Recipe>>> getRecipes() async {
    try {
      final recipes = await _recipeApi.getRecipes();
      return Right(recipes);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Recipe>> getRecipe(String id) async {
    try {
      final recipe = await _recipeApi.getRecipe(id);
      return Right(recipe);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Recipe>> createRecipe(
    RecipeCreate recipe,
  ) async {
    try {
      final created = await _recipeApi.createRecipe(recipe);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Recipe>> updateRecipe(
    String id,
    RecipeCreate recipe,
  ) async {
    try {
      final updated = await _recipeApi.updateRecipe(id, recipe);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deleteRecipe(String id) async {
    try {
      await _recipeApi.deleteRecipe(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, List<Recipe>>> searchRecipes(
    String query,
  ) async {
    try {
      final recipes = await _recipeApi.searchRecipes(query);
      return Right(recipes);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Recipe>> importRecipe(String url) async {
    try {
      final recipe = await _recipeApi.importRecipe({'url': url});
      return Right(recipe);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, String>> uploadImage(
    String recipeId,
    File imageFile,
  ) async {
    try {
      final result = await _recipeApi.uploadImage(recipeId, imageFile);
      final imageUrl = result['image_url'];
      if (imageUrl == null) {
        return const Left(ApiException.unknown('No image URL returned'));
      }
      return Right(imageUrl);
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
