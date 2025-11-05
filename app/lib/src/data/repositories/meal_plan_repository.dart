/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/meal_plan_api.dart';
import '../models/meal_plan.dart';

class MealPlanRepository {
  final MealPlanApi _mealPlanApi;

  MealPlanRepository(this._mealPlanApi);

  Future<Either<ApiException, List<MealPlan>>> getMealPlans({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final mealPlans = await _mealPlanApi.getMealPlans(
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
      return Right(mealPlans);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, MealPlan>> getMealPlan(String id) async {
    try {
      final mealPlan = await _mealPlanApi.getMealPlan(id);
      return Right(mealPlan);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, MealPlan>> createMealPlan(
    MealPlanCreate mealPlan,
  ) async {
    try {
      final created = await _mealPlanApi.createMealPlan(mealPlan);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, MealPlan>> updateMealPlan(
    String id,
    MealPlanCreate mealPlan,
  ) async {
    try {
      final updated = await _mealPlanApi.updateMealPlan(id, mealPlan);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deleteMealPlan(String id) async {
    try {
      await _mealPlanApi.deleteMealPlan(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, PlannedMeal>> addPlannedMeal(
    String mealPlanId,
    PlannedMealCreate meal,
  ) async {
    try {
      final created = await _mealPlanApi.addPlannedMeal(mealPlanId, meal);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deletePlannedMeal(
    String mealPlanId,
    String mealId,
  ) async {
    try {
      await _mealPlanApi.deletePlannedMeal(mealPlanId, mealId);
      return const Right(null);
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
