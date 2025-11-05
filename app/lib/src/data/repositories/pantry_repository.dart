/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/pantry_api.dart';
import '../models/pantry.dart';

class PantryRepository {
  final PantryApi _pantryApi;

  PantryRepository(this._pantryApi);

  Future<Either<ApiException, List<PantryItem>>> getPantryItems({
    String? category,
  }) async {
    try {
      final items = await _pantryApi.getPantryItems(category: category);
      return Right(items);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, PantryItem>> getPantryItem(String id) async {
    try {
      final item = await _pantryApi.getPantryItem(id);
      return Right(item);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, PantryItem>> createPantryItem(
    PantryItemCreate item,
  ) async {
    try {
      final created = await _pantryApi.createPantryItem(item);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, PantryItem>> updatePantryItem(
    String id,
    PantryItemCreate item,
  ) async {
    try {
      final updated = await _pantryApi.updatePantryItem(id, item);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deletePantryItem(String id) async {
    try {
      await _pantryApi.deletePantryItem(id);
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
