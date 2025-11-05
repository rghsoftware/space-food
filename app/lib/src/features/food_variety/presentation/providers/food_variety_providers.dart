// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/food_variety_database.dart';
import '../../data/remote/food_variety_api_client.dart';
import '../../data/repositories/food_variety_repository.dart';
import '../../data/models/food_hyperfixation.dart';
import '../../data/models/food_chain_suggestion.dart';
import '../../data/models/food_variation.dart';
import '../../data/models/variety_analysis.dart';
import '../../data/models/nutrition_settings.dart';
import '../../data/models/rotation_schedule.dart';

part 'food_variety_providers.g.dart';

// Database provider
@riverpod
FoodVarietyDatabase foodVarietyDatabase(FoodVarietyDatabaseRef ref) {
  return FoodVarietyDatabase();
}

// API client provider
@riverpod
FoodVarietyApiClient foodVarietyApiClient(FoodVarietyApiClientRef ref) {
  // TODO: Get Dio instance from shared provider
  throw UnimplementedError('Dio instance provider needed');
}

// Repository provider
@riverpod
FoodVarietyRepository foodVarietyRepository(FoodVarietyRepositoryRef ref) {
  return FoodVarietyRepository(
    apiClient: ref.watch(foodVarietyApiClientProvider),
    database: ref.watch(foodVarietyDatabaseProvider),
  );
}

// Hyperfixation providers

@riverpod
Future<List<FoodHyperfixation>> activeHyperfixations(
  ActiveHyperfixationsRef ref,
  String userId,
) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getActiveHyperfixations(userId);
  return result.fold(
    (error) => throw Exception(error),
    (hyperfixations) => hyperfixations,
  );
}

@riverpod
class HyperfixationRecorder extends _$HyperfixationRecorder {
  @override
  FutureOr<void> build() => null;

  Future<void> recordHyperfixation({
    required String foodName,
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = RecordHyperfixationRequest(
      foodName: foodName,
      notes: notes,
    );

    final result = await repository.recordHyperfixation(request);
    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }
}

// Chain Suggestion providers

@riverpod
class ChainSuggestionGenerator extends _$ChainSuggestionGenerator {
  @override
  FutureOr<List<FoodChainSuggestion>?> build() => null;

  Future<List<FoodChainSuggestion>> generateSuggestions({
    required String foodName,
    required String userId,
    int count = 5,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = GenerateChainSuggestionsRequest(
      foodName: foodName,
      count: count,
    );

    final result =
        await repository.generateChainSuggestions(request, userId);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (suggestions) {
        state = AsyncValue.data(suggestions);
        return suggestions;
      },
    );
  }
}

@riverpod
Future<List<FoodChainSuggestion>> userChainSuggestions(
  UserChainSuggestionsRef ref,
  String userId, {
  int limit = 20,
  int offset = 0,
}) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getUserChainSuggestions(
    userId,
    limit: limit,
    offset: offset,
  );
  return result.fold(
    (error) => throw Exception(error),
    (suggestions) => suggestions,
  );
}

@riverpod
class ChainFeedbackRecorder extends _$ChainFeedbackRecorder {
  @override
  FutureOr<void> build() => null;

  Future<void> recordFeedback({
    required String suggestionId,
    required bool wasLiked,
    String? feedback,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = RecordChainFeedbackRequest(
      wasLiked: wasLiked,
      feedback: feedback,
    );

    final result =
        await repository.recordChainFeedback(suggestionId, request);
    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }
}

// Variation providers

@riverpod
Future<List<FoodVariation>> variationIdeas(
  VariationIdeasRef ref,
  String foodName,
) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getVariationIdeas(foodName);
  return result.fold(
    (error) => throw Exception(error),
    (variations) => variations,
  );
}

// Variety Analysis provider

@riverpod
Future<VarietyAnalysis> varietyAnalysis(VarietyAnalysisRef ref) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getVarietyAnalysis();
  return result.fold(
    (error) => throw Exception(error),
    (analysis) => analysis,
  );
}

// Nutrition Settings providers

@riverpod
Future<NutritionTrackingSettings> nutritionSettings(
  NutritionSettingsRef ref,
  String userId,
) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getNutritionSettings(userId);
  return result.fold(
    (error) => throw Exception(error),
    (settings) => settings,
  );
}

@riverpod
class NutritionSettingsUpdater extends _$NutritionSettingsUpdater {
  @override
  FutureOr<NutritionTrackingSettings?> build() => null;

  Future<NutritionTrackingSettings> updateSettings({
    required String userId,
    bool? trackingEnabled,
    bool? showCalorieCounts,
    bool? showMacros,
    bool? showMicronutrients,
    List<String>? focusNutrients,
    bool? showWeeklySummary,
    bool? showDailySummary,
    String? reminderStyle,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = UpdateNutritionSettingsRequest(
      trackingEnabled: trackingEnabled,
      showCalorieCounts: showCalorieCounts,
      showMacros: showMacros,
      showMicronutrients: showMicronutrients,
      focusNutrients: focusNutrients,
      showWeeklySummary: showWeeklySummary,
      showDailySummary: showDailySummary,
      reminderStyle: reminderStyle,
    );

    final result =
        await repository.updateNutritionSettings(request, userId);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (settings) {
        state = AsyncValue.data(settings);
        // Invalidate the settings provider to refresh
        ref.invalidate(nutritionSettingsProvider);
        return settings;
      },
    );
  }
}

// Nutrition Insights providers

@riverpod
Future<List<NutritionInsight>> weeklyInsights(
  WeeklyInsightsRef ref,
  String userId,
) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getWeeklyInsights(userId);
  return result.fold(
    (error) => throw Exception(error),
    (insights) => insights,
  );
}

@riverpod
class InsightGenerator extends _$InsightGenerator {
  @override
  FutureOr<List<NutritionInsight>?> build() => null;

  Future<List<NutritionInsight>> generateInsights({
    required String userId,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final result = await repository.generateWeeklyInsights(userId);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (insights) {
        state = AsyncValue.data(insights);
        // Invalidate the insights provider to refresh
        ref.invalidate(weeklyInsightsProvider);
        return insights;
      },
    );
  }
}

@riverpod
class InsightDismisser extends _$InsightDismisser {
  @override
  FutureOr<void> build() => null;

  Future<void> dismissInsight(String insightId) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final result = await repository.dismissInsight(insightId);
    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }
}

// Rotation Schedule providers

@riverpod
Future<List<FoodRotationSchedule>> rotationSchedules(
  RotationSchedulesRef ref,
  String userId,
) async {
  final repository = ref.watch(foodVarietyRepositoryProvider);
  final result = await repository.getRotationSchedules(userId);
  return result.fold(
    (error) => throw Exception(error),
    (schedules) => schedules,
  );
}

@riverpod
class RotationScheduleCreator extends _$RotationScheduleCreator {
  @override
  FutureOr<FoodRotationSchedule?> build() => null;

  Future<FoodRotationSchedule> createSchedule({
    required String scheduleName,
    required int rotationDays,
    required List<RotationFood> foods,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = CreateRotationScheduleRequest(
      scheduleName: scheduleName,
      rotationDays: rotationDays,
      foods: foods,
    );

    final result = await repository.createRotationSchedule(request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (schedule) {
        state = AsyncValue.data(schedule);
        // Invalidate the schedules list to refresh
        ref.invalidate(rotationSchedulesProvider);
        return schedule;
      },
    );
  }
}

@riverpod
class RotationScheduleUpdater extends _$RotationScheduleUpdater {
  @override
  FutureOr<FoodRotationSchedule?> build() => null;

  Future<FoodRotationSchedule> updateSchedule({
    required String scheduleId,
    String? scheduleName,
    int? rotationDays,
    List<RotationFood>? foods,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final request = UpdateRotationScheduleRequest(
      scheduleName: scheduleName,
      rotationDays: rotationDays,
      foods: foods,
      isActive: isActive,
    );

    final result =
        await repository.updateRotationSchedule(scheduleId, request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (schedule) {
        state = AsyncValue.data(schedule);
        // Invalidate the schedules list to refresh
        ref.invalidate(rotationSchedulesProvider);
        return schedule;
      },
    );
  }
}

@riverpod
class RotationScheduleDeleter extends _$RotationScheduleDeleter {
  @override
  FutureOr<void> build() => null;

  Future<void> deleteSchedule(String scheduleId) async {
    state = const AsyncValue.loading();

    final repository = ref.read(foodVarietyRepositoryProvider);
    final result = await repository.deleteRotationSchedule(scheduleId);
    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (_) {
        state = const AsyncValue.data(null);
        // Invalidate the schedules list to refresh
        ref.invalidate(rotationSchedulesProvider);
      },
    );
  }
}
