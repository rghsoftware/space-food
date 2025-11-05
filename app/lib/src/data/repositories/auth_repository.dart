/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../api/auth_api.dart';
import '../models/user.dart';

class AuthRepository {
  final AuthApi _authApi;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._authApi, this._secureStorage);

  Future<Either<ApiException, AuthResponse>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      final response = await _authApi.register(request);

      // Store tokens securely
      await _storeTokens(response);

      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _authApi.login(request);

      // Store tokens securely
      await _storeTokens(response);

      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, AuthResponse>> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: AppConfig.refreshTokenKey,
      );

      if (refreshToken == null) {
        return const Left(
          ApiException.unauthorized('No refresh token available'),
        );
      }

      final response = await _authApi.refresh({
        'refresh_token': refreshToken,
      });

      // Store new tokens
      await _storeTokens(response);

      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConfig.accessTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> _storeTokens(AuthResponse response) async {
    await _secureStorage.write(
      key: AppConfig.accessTokenKey,
      value: response.accessToken,
    );
    await _secureStorage.write(
      key: AppConfig.refreshTokenKey,
      value: response.refreshToken,
    );
    await _secureStorage.write(
      key: AppConfig.userIdKey,
      value: response.user.id,
    );
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
    final message = error.response?.data['error'] ?? error.message ?? 'Unknown error';

    if (statusCode != null) {
      return ApiException.fromStatusCode(statusCode, message);
    }

    return ApiException.unknown(message);
  }
}
