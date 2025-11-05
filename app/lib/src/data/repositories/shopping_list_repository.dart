/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/shopping_list_api.dart';
import '../models/shopping_list.dart';

class ShoppingListRepository {
  final ShoppingListApi _shoppingListApi;

  ShoppingListRepository(this._shoppingListApi);

  Future<Either<ApiException, List<ShoppingListItem>>>
      getShoppingListItems() async {
    try {
      final items = await _shoppingListApi.getShoppingListItems();
      return Right(items);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, ShoppingListItem>> getShoppingListItem(
    String id,
  ) async {
    try {
      final item = await _shoppingListApi.getShoppingListItem(id);
      return Right(item);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, ShoppingListItem>> createShoppingListItem(
    ShoppingListItemCreate item,
  ) async {
    try {
      final created = await _shoppingListApi.createShoppingListItem(item);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, ShoppingListItem>> updateShoppingListItem(
    String id,
    ShoppingListItemCreate item,
  ) async {
    try {
      final updated = await _shoppingListApi.updateShoppingListItem(id, item);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, ShoppingListItem>> toggleShoppingListItem(
    String id,
  ) async {
    try {
      final updated = await _shoppingListApi.toggleShoppingListItem(id);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deleteShoppingListItem(String id) async {
    try {
      await _shoppingListApi.deleteShoppingListItem(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> clearCompleted() async {
    try {
      await _shoppingListApi.clearCompleted();
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
