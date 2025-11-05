/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_exception.freezed.dart';

@freezed
class ApiException with _$ApiException implements Exception {
  const factory ApiException.network(String message) = _NetworkException;
  const factory ApiException.unauthorized(String message) = _UnauthorizedException;
  const factory ApiException.forbidden(String message) = _ForbiddenException;
  const factory ApiException.notFound(String message) = _NotFoundException;
  const factory ApiException.serverError(String message) = _ServerException;
  const factory ApiException.timeout(String message) = _TimeoutException;
  const factory ApiException.unknown(String message) = _UnknownException;

  factory ApiException.fromStatusCode(int statusCode, String message) {
    switch (statusCode) {
      case 401:
        return ApiException.unauthorized(message);
      case 403:
        return ApiException.forbidden(message);
      case 404:
        return ApiException.notFound(message);
      case >= 500:
        return ApiException.serverError(message);
      default:
        return ApiException.unknown(message);
    }
  }
}
