/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exception.dart';
import '../api/household_api.dart';
import '../models/household.dart';

class HouseholdRepository {
  final HouseholdApi _householdApi;

  HouseholdRepository(this._householdApi);

  Future<Either<ApiException, List<Household>>> getHouseholds() async {
    try {
      final households = await _householdApi.getHouseholds();
      return Right(households);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Household>> getHousehold(String id) async {
    try {
      final household = await _householdApi.getHousehold(id);
      return Right(household);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Household>> createHousehold(
    HouseholdCreate household,
  ) async {
    try {
      final created = await _householdApi.createHousehold(household);
      return Right(created);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, Household>> updateHousehold(
    String id,
    HouseholdCreate household,
  ) async {
    try {
      final updated = await _householdApi.updateHousehold(id, household);
      return Right(updated);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> deleteHousehold(String id) async {
    try {
      await _householdApi.deleteHousehold(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, List<HouseholdMember>>> getMembers(
    String id,
  ) async {
    try {
      final members = await _householdApi.getMembers(id);
      return Right(members);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, HouseholdMember>> addMember(
    String householdId,
    HouseholdInvitation invitation,
  ) async {
    try {
      final member = await _householdApi.addMember(householdId, invitation);
      return Right(member);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  Future<Either<ApiException, void>> removeMember(
    String householdId,
    String userId,
  ) async {
    try {
      await _householdApi.removeMember(householdId, userId);
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
