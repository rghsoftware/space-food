/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/api/energy_tracking_api.dart';
import '../../data/local/energy_tracking_database.dart';
import '../../data/repositories/energy_tracking_repository.dart';
import '../../data/models/energy_snapshot.dart';
import '../../data/models/favorite_meal.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/dio_provider.dart';

part 'energy_tracking_providers.g.dart';

// ==================== Infrastructure Providers ====================

/// Provides the Drift database instance for energy tracking
@riverpod
EnergyTrackingDatabase energyTrackingDatabase(
    EnergyTrackingDatabaseRef ref) {
  return EnergyTrackingDatabase();
}

/// Provides the energy tracking API client
@riverpod
EnergyTrackingApi energyTrackingApi(EnergyTrackingApiRef ref) {
  final dio = ref.watch(dioProvider);
  return EnergyTrackingApi(dio, baseUrl: '${dio.options.baseUrl}/api/v1');
}

/// Provides the energy tracking repository
@riverpod
EnergyTrackingRepository energyTrackingRepository(
    EnergyTrackingRepositoryRef ref) {
  final api = ref.watch(energyTrackingApiProvider);
  final database = ref.watch(energyTrackingDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);

  return EnergyTrackingRepository(api, database, userId);
}

// ==================== Energy Recording ====================

/// Record energy level
@riverpod
class EnergyRecorder extends _$EnergyRecorder {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Record energy level with optional context
  Future<EnergySnapshot> recordEnergy(int energyLevel, {String? context}) async {
    state = const AsyncValue.loading();

    final repository = ref.read(energyTrackingRepositoryProvider);
    final request = RecordEnergyRequest(
      energyLevel: energyLevel,
      context: context,
    );

    final result = await repository.recordEnergy(request);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (error) => throw error,
        (snapshot) {
          // Invalidate history to refresh
          ref.invalidate(energyHistoryProvider);
          return snapshot;
        },
      );
    });

    return result.fold(
      (error) => throw error,
      (snapshot) => snapshot,
    );
  }
}

/// Get energy history
@riverpod
class EnergyHistory extends _$EnergyHistory {
  @override
  Future<EnergySnapshotsResponse> build({int days = 30}) async {
    final repository = ref.watch(energyTrackingRepositoryProvider);
    final result = await repository.getEnergyHistory(days: days);

    return result.fold(
      (error) => throw error,
      (history) => history,
    );
  }

  /// Refresh energy history
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Get energy patterns
@riverpod
Future<List<UserEnergyPattern>> energyPatterns(EnergyPatternsRef ref) async {
  final repository = ref.watch(energyTrackingRepositoryProvider);
  final result = await repository.getEnergyPatterns();

  return result.fold(
    (error) => throw error,
    (patterns) => patterns,
  );
}

// ==================== Energy-Based Recommendations ====================

/// Get energy-based meal recommendations
@riverpod
class EnergyRecommendations extends _$EnergyRecommendations {
  @override
  Future<EnergyBasedRecommendation> build(int? energyLevel) async {
    final repository = ref.watch(energyTrackingRepositoryProvider);
    final result = await repository.getRecommendations(
      energyLevel: energyLevel,
    );

    return result.fold(
      (error) => throw error,
      (recommendations) => recommendations,
    );
  }

  /// Refresh recommendations
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ==================== Favorite Meals ====================

/// Provides list of favorite meals
@riverpod
class FavoriteMeals extends _$FavoriteMeals {
  @override
  Future<List<FavoriteMeal>> build({
    int? energyLevel,
    String? timeOfDay,
    int? maxResults,
  }) async {
    final repository = ref.watch(energyTrackingRepositoryProvider);
    final result = await repository.getFavoriteMeals(
      energyLevel: energyLevel,
      timeOfDay: timeOfDay,
      maxResults: maxResults,
    );

    return result.fold(
      (error) => throw error,
      (meals) => meals,
    );
  }

  /// Create a new favorite meal
  Future<FavoriteMeal> createMeal(SaveFavoriteMealRequest request) async {
    final repository = ref.read(energyTrackingRepositoryProvider);
    final result = await repository.saveFavoriteMeal(request);

    return result.fold(
      (error) => throw error,
      (meal) {
        // Invalidate to refresh list
        ref.invalidateSelf();
        ref.invalidate(energyRecommendationsProvider);
        return meal;
      },
    );
  }

  /// Update an existing favorite meal
  Future<FavoriteMeal> updateMeal(
    String id,
    UpdateFavoriteMealRequest request,
  ) async {
    final repository = ref.read(energyTrackingRepositoryProvider);
    final result = await repository.updateFavoriteMeal(id, request);

    return result.fold(
      (error) => throw error,
      (meal) {
        // Invalidate to refresh list
        ref.invalidateSelf();
        ref.invalidate(energyRecommendationsProvider);
        return meal;
      },
    );
  }

  /// Mark meal as eaten (increments frequency)
  Future<void> markMealEaten(String id) async {
    final repository = ref.read(energyTrackingRepositoryProvider);
    final result = await repository.markMealEaten(id);

    await result.fold(
      (error) => throw error,
      (_) async {
        // Invalidate to refresh list
        ref.invalidateSelf();
        ref.invalidate(energyRecommendationsProvider);
      },
    );
  }

  /// Delete a favorite meal
  Future<void> deleteMeal(String id) async {
    final repository = ref.read(energyTrackingRepositoryProvider);
    final result = await repository.deleteFavoriteMeal(id);

    await result.fold(
      (error) => throw error,
      (_) async {
        // Invalidate to refresh list
        ref.invalidateSelf();
        ref.invalidate(energyRecommendationsProvider);
      },
    );
  }

  /// Refresh meals list
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provides a single favorite meal by ID
@riverpod
Future<FavoriteMeal?> favoriteMeal(FavoriteMealRef ref, String id) async {
  final meals = await ref.watch(favoriteMealsProvider().future);
  try {
    return meals.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

// ==================== Integrated Meal Logger ====================

/// Logs a meal and optionally records energy
@riverpod
class MealWithEnergyLogger extends _$MealWithEnergyLogger {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Log a meal from a favorite and record energy
  Future<void> logMealWithEnergy(
    String mealId,
    int energyLevel,
  ) async {
    state = const AsyncValue.loading();

    // Mark meal as eaten
    final mealsNotifier = ref.read(favoriteMealsProvider().notifier);
    await mealsNotifier.markMealEaten(mealId);

    // Record energy level
    final energyNotifier = ref.read(energyRecorderProvider.notifier);
    await energyNotifier.recordEnergy(energyLevel, context: 'meal_log');

    state = const AsyncValue.data(null);
  }
}

// ==================== Helper Providers ====================

/// Provides current time of day
@riverpod
String currentTimeOfDay(CurrentTimeOfDayRef ref) {
  final now = DateTime.now();
  final hour = now.hour;

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

/// Provides predicted energy level based on patterns
@riverpod
Future<int> predictedEnergyLevel(PredictedEnergyLevelRef ref) async {
  try {
    final patterns = await ref.watch(energyPatternsProvider.future);
    final timeOfDay = ref.watch(currentTimeOfDayProvider);
    final now = DateTime.now();
    final dayOfWeek = now.weekday % 7; // 0=Sunday

    // Find matching pattern
    final matchingPattern = patterns.where((p) =>
        p.timeOfDay == timeOfDay && p.dayOfWeek == dayOfWeek);

    if (matchingPattern.isNotEmpty) {
      return matchingPattern.first.typicalEnergyLevel;
    }

    // Default to moderate if no pattern found
    return 3;
  } catch (_) {
    return 3; // Default to moderate
  }
}

/// Provides recommended meals for right now
@riverpod
Future<List<FavoriteMeal>> recommendedMealsNow(
    RecommendedMealsNowRef ref) async {
  final predictedEnergy = await ref.watch(predictedEnergyLevelProvider.future);
  final timeOfDay = ref.watch(currentTimeOfDayProvider);

  final meals = await ref.watch(favoriteMealsProvider(
    energyLevel: predictedEnergy,
    timeOfDay: timeOfDay,
    maxResults: 5,
  ).future);

  return meals;
}
