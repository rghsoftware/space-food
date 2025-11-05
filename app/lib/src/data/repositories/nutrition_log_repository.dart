/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/nutrition_log_api.dart';
import '../models/nutrition_log.dart';

class NutritionLogRepository {
  final NutritionLogApi _nutritionLogApi;

  NutritionLogRepository(this._nutritionLogApi);

  Future<Either<ApiException, List<NutritionLog>>> getNutritionLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await _nutritionLogApi.getNutritionLogs(
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
      return Right(logs);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, NutritionLog>> getNutritionLog(String id) async {
    try {
      final log = await _nutritionLogApi.getNutritionLog(id);
      return Right(log);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, NutritionLog>> createNutritionLog(
    NutritionLogCreate log,
  ) async {
    try {
      final created = await _nutritionLogApi.createNutritionLog(log);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deleteNutritionLog(String id) async {
    try {
      await _nutritionLogApi.deleteNutritionLog(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Map<String, dynamic>>> getNutritionSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final summary = await _nutritionLogApi.getNutritionSummary(
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );
      return Right(summary);
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
