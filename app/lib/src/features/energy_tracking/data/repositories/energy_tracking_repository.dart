/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_exception.dart';
import '../api/energy_tracking_api.dart';
import '../local/energy_tracking_database.dart';
import '../models/energy_snapshot.dart';
import '../models/favorite_meal.dart';

/// Repository implementing offline-first energy tracking functionality
class EnergyTrackingRepository {
  final EnergyTrackingApi _api;
  final EnergyTrackingDatabase _database;
  final String _userId;
  final _uuid = const Uuid();

  EnergyTrackingRepository(
    this._api,
    this._database,
    this._userId,
  );

  // ==================== Energy Snapshots ====================

  /// Record energy level - saves locally first, syncs when online
  Future<Either<ApiException, EnergySnapshot>> recordEnergy(
    RecordEnergyRequest request,
  ) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final timeOfDay = _getTimeOfDay(now);

    // Save locally first
    final localSnapshot = EnergySnapshotsCompanion(
      id: drift.Value(id),
      userId: drift.Value(_userId),
      recordedAt: drift.Value(now),
      energyLevel: drift.Value(request.energyLevel),
      timeOfDay: drift.Value(timeOfDay),
      dayOfWeek: drift.Value(now.weekday % 7), // 0=Sunday
      context: drift.Value(request.context),
      createdAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.insertSnapshot(localSnapshot);

    // Try to sync with server
    try {
      final serverSnapshot = await _api.recordEnergy(request);
      await _database.markSnapshotSynced(serverSnapshot.id);
      return Right(serverSnapshot);
    } on DioException {
      // Return local version if offline
      return Right(EnergySnapshot(
        id: id,
        userId: _userId,
        recordedAt: now,
        energyLevel: request.energyLevel,
        timeOfDay: timeOfDay,
        dayOfWeek: now.weekday % 7,
        context: request.context,
        createdAt: now,
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Get energy history - tries API first, falls back to local
  Future<Either<ApiException, EnergySnapshotsResponse>> getEnergyHistory({
    int days = 30,
  }) async {
    try {
      final response = await _api.getEnergyHistory(days);
      return Right(response);
    } on DioException {
      // Fall back to local data
      final localSnapshots = await _database.getAllSnapshots(_userId, days: days);
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      return Right(EnergySnapshotsResponse(
        snapshots: localSnapshots
            .map((snap) => EnergySnapshot(
                  id: snap.id,
                  userId: snap.userId,
                  recordedAt: snap.recordedAt,
                  energyLevel: snap.energyLevel,
                  timeOfDay: snap.timeOfDay,
                  dayOfWeek: snap.dayOfWeek,
                  context: snap.context,
                  createdAt: snap.createdAt,
                ))
            .toList(),
        startDate: startDate,
        endDate: endDate,
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Get energy patterns - tries API first, falls back to local
  Future<Either<ApiException, List<UserEnergyPattern>>> getEnergyPatterns() async {
    try {
      final response = await _api.getEnergyPatterns();
      final patterns = (response['patterns'] as List)
          .map((p) => UserEnergyPattern.fromJson(p as Map<String, dynamic>))
          .toList();
      return Right(patterns);
    } on DioException {
      // Fall back to local data
      final localPatterns = await _database.getAllPatterns(_userId);
      return Right(localPatterns
          .map((p) => UserEnergyPattern(
                id: p.id,
                userId: p.userId,
                timeOfDay: p.timeOfDay,
                dayOfWeek: p.dayOfWeek,
                typicalEnergyLevel: p.typicalEnergyLevel,
                sampleCount: p.sampleCount,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
              ))
          .toList());
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Recommendations ====================

  /// Get energy-based meal recommendations
  Future<Either<ApiException, EnergyBasedRecommendation>> getRecommendations({
    int? energyLevel,
  }) async {
    try {
      final recommendations = await _api.getRecommendations(energyLevel);
      return Right(recommendations);
    } on DioException {
      // Fall back to local favorite meals
      final timeOfDay = _getTimeOfDay(DateTime.now());
      final meals = await _database.getFavoriteMealsByEnergy(
        _userId,
        energyLevel,
        timeOfDay,
      );

      return Right(EnergyBasedRecommendation(
        meals: meals
            .map((m) => FavoriteMeal(
                  id: m.id,
                  userId: m.userId,
                  recipeId: m.recipeId,
                  mealName: m.mealName,
                  energyLevel: m.energyLevel,
                  typicalTimeOfDay: m.typicalTimeOfDay,
                  frequencyScore: m.frequencyScore,
                  lastEaten: m.lastEaten,
                  notes: m.notes,
                  createdAt: m.createdAt,
                  updatedAt: m.updatedAt,
                ))
            .toList(),
        currentEnergy: energyLevel ?? 3,
        timeOfDay: timeOfDay,
        reasoning: _generateReasoning(energyLevel ?? 3, timeOfDay, meals.length),
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Favorite Meals ====================

  /// Save a new favorite meal
  Future<Either<ApiException, FavoriteMeal>> saveFavoriteMeal(
    SaveFavoriteMealRequest request,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Save locally first
    final localMeal = FavoriteMealsCompanion(
      id: drift.Value(id),
      userId: drift.Value(_userId),
      recipeId: drift.Value(request.recipeId),
      mealName: drift.Value(request.mealName),
      energyLevel: drift.Value(request.energyLevel),
      typicalTimeOfDay: drift.Value(request.typicalTimeOfDay),
      notes: drift.Value(request.notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.insertFavoriteMeal(localMeal);

    // Try to sync with server
    try {
      final serverMeal = await _api.saveFavoriteMeal(request);
      await _database.markMealSynced(serverMeal.id);
      return Right(serverMeal);
    } on DioException {
      // Return local version if offline
      return Right(FavoriteMeal(
        id: id,
        userId: _userId,
        recipeId: request.recipeId,
        mealName: request.mealName,
        energyLevel: request.energyLevel,
        typicalTimeOfDay: request.typicalTimeOfDay,
        notes: request.notes,
        createdAt: now,
        updatedAt: now,
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Get favorite meals with optional filtering
  Future<Either<ApiException, List<FavoriteMeal>>> getFavoriteMeals({
    int? energyLevel,
    String? timeOfDay,
    int? maxResults,
  }) async {
    try {
      final response = await _api.getFavoriteMeals(
        energyLevel,
        timeOfDay,
        maxResults,
      );
      final meals = (response['meals'] as List)
          .map((m) => FavoriteMeal.fromJson(m as Map<String, dynamic>))
          .toList();
      return Right(meals);
    } on DioException {
      // Fall back to local data
      final localMeals = await _database.getFavoriteMealsByEnergy(
        _userId,
        energyLevel,
        timeOfDay,
      );

      var meals = localMeals
          .map((m) => FavoriteMeal(
                id: m.id,
                userId: m.userId,
                recipeId: m.recipeId,
                mealName: m.mealName,
                energyLevel: m.energyLevel,
                typicalTimeOfDay: m.typicalTimeOfDay,
                frequencyScore: m.frequencyScore,
                lastEaten: m.lastEaten,
                notes: m.notes,
                createdAt: m.createdAt,
                updatedAt: m.updatedAt,
              ))
          .toList();

      if (maxResults != null && meals.length > maxResults) {
        meals = meals.sublist(0, maxResults);
      }

      return Right(meals);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Update a favorite meal
  Future<Either<ApiException, FavoriteMeal>> updateFavoriteMeal(
    String id,
    UpdateFavoriteMealRequest request,
  ) async {
    final now = DateTime.now();

    // Update locally first
    final localMeal = await _database.getFavoriteMealById(id);
    if (localMeal != null) {
      final updatedMeal = FavoriteMealsCompanion(
        id: drift.Value(id),
        userId: drift.Value(localMeal.userId),
        recipeId: drift.Value(localMeal.recipeId),
        mealName: drift.Value(request.mealName),
        energyLevel: drift.Value(request.energyLevel),
        typicalTimeOfDay: drift.Value(request.typicalTimeOfDay),
        notes: drift.Value(request.notes),
        frequencyScore: drift.Value(localMeal.frequencyScore),
        lastEaten: drift.Value(localMeal.lastEaten),
        createdAt: drift.Value(localMeal.createdAt),
        updatedAt: drift.Value(now),
        syncedToServer: const drift.Value(false),
      );
      await _database.updateFavoriteMeal(updatedMeal);
    }

    // Try to sync with server
    try {
      final serverMeal = await _api.updateFavoriteMeal(id, request);
      await _database.markMealSynced(serverMeal.id);
      return Right(serverMeal);
    } on DioException {
      // Return local version if offline
      if (localMeal != null) {
        return Right(FavoriteMeal(
          id: id,
          userId: localMeal.userId,
          recipeId: localMeal.recipeId,
          mealName: request.mealName,
          energyLevel: request.energyLevel,
          typicalTimeOfDay: request.typicalTimeOfDay,
          notes: request.notes,
          frequencyScore: localMeal.frequencyScore,
          lastEaten: localMeal.lastEaten,
          createdAt: localMeal.createdAt,
          updatedAt: now,
        ));
      }
      return const Left(ApiException.unknown('Meal not found locally'));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Mark meal as eaten (increments frequency)
  Future<Either<ApiException, void>> markMealEaten(String id) async {
    // Increment locally first
    await _database.incrementMealFrequency(id);

    // Try to sync with server
    try {
      await _api.markMealEaten(id);
      return const Right(null);
    } on DioException {
      // Offline - will sync later
      return const Right(null);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Delete a favorite meal
  Future<Either<ApiException, void>> deleteFavoriteMeal(String id) async {
    try {
      await _api.deleteFavoriteMeal(id);
      await _database.deleteFavoriteMeal(id);
      return const Right(null);
    } on DioException {
      // Delete locally even if offline
      await _database.deleteFavoriteMeal(id);
      return const Right(null);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Helper Methods ====================

  String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  String _generateReasoning(int energyLevel, String timeOfDay, int mealCount) {
    if (mealCount == 0) {
      return 'No favorite meals saved yet. Add some meals you enjoy to get personalized recommendations!';
    }

    String energyDesc;
    if (energyLevel <= 2) {
      energyDesc = 'low energy';
    } else if (energyLevel == 3) {
      energyDesc = 'moderate energy';
    } else {
      energyDesc = 'good energy';
    }

    return 'Showing meals appropriate for your $energyDesc this $timeOfDay. '
        'These meals match your energy level and typical eating patterns.';
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
