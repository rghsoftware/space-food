// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:either_dart/either.dart';
import '../local/food_variety_database.dart';
import '../remote/food_variety_api_client.dart';
import '../models/food_hyperfixation.dart';
import '../models/food_chain_suggestion.dart';
import '../models/food_variation.dart';
import '../models/variety_analysis.dart';
import '../models/nutrition_settings.dart';
import '../models/rotation_schedule.dart';

class FoodVarietyRepository {
  final FoodVarietyApiClient apiClient;
  final FoodVarietyDatabase database;

  FoodVarietyRepository({
    required this.apiClient,
    required this.database,
  });

  // Hyperfixation operations

  Future<Either<String, List<FoodHyperfixation>>> getActiveHyperfixations(
      String userId) async {
    try {
      final response = await apiClient.getActiveHyperfixations();
      final hyperfixations = response.hyperfixations;

      // Update local cache
      for (final hyperfixation in hyperfixations) {
        await database.insertHyperfixation(FoodHyperfixationsCompanion(
          id: drift.Value(hyperfixation.id),
          userId: drift.Value(hyperfixation.userId),
          foodName: drift.Value(hyperfixation.foodName),
          startedAt: drift.Value(hyperfixation.startedAt),
          frequencyCount: drift.Value(hyperfixation.frequencyCount),
          peakFrequencyPerDay: drift.Value(hyperfixation.peakFrequencyPerDay),
          isActive: drift.Value(hyperfixation.isActive),
          endedAt: drift.Value(hyperfixation.endedAt),
          notes: drift.Value(hyperfixation.notes),
          createdAt: drift.Value(hyperfixation.createdAt),
          updatedAt: drift.Value(hyperfixation.updatedAt),
          syncedToServer: const drift.Value(true),
        ));
      }

      return Right(hyperfixations);
    } catch (e) {
      // Fall back to local database
      try {
        final local = await database.getActiveHyperfixations(userId);
        return Right(local.map(_hyperfixationFromDatabase).toList());
      } catch (localError) {
        return Left('Failed to get hyperfixations: $e');
      }
    }
  }

  Future<Either<String, void>> recordHyperfixation(
      RecordHyperfixationRequest request) async {
    try {
      await apiClient.recordHyperfixation(request);
      return const Right(null);
    } catch (e) {
      return Left('Failed to record hyperfixation: $e');
    }
  }

  // Chain Suggestion operations

  Future<Either<String, List<FoodChainSuggestion>>> generateChainSuggestions(
      GenerateChainSuggestionsRequest request, String userId) async {
    try {
      final response = await apiClient.generateChainSuggestions(request);
      final suggestions = response.suggestions;

      // Save to local database
      for (final suggestion in suggestions) {
        await database.insertSuggestion(FoodChainSuggestionsCompanion(
          id: drift.Value(suggestion.id),
          userId: drift.Value(suggestion.userId),
          currentFoodName: drift.Value(suggestion.currentFoodName),
          suggestedFoodName: drift.Value(suggestion.suggestedFoodName),
          similarityScore: drift.Value(suggestion.similarityScore),
          reasoning: drift.Value(suggestion.reasoning),
          wasTried: drift.Value(suggestion.wasTried),
          wasLiked: drift.Value(suggestion.wasLiked),
          triedAt: drift.Value(suggestion.triedAt),
          feedback: drift.Value(suggestion.feedback),
          createdAt: drift.Value(suggestion.createdAt),
          syncedToServer: const drift.Value(true),
        ));
      }

      return Right(suggestions);
    } catch (e) {
      // Fall back to local cache if available
      try {
        final local =
            await database.getSuggestionsForFood(userId, request.foodName);
        if (local.isNotEmpty) {
          return Right(local.map(_suggestionFromDatabase).toList());
        }
      } catch (_) {}

      return Left('Failed to generate chain suggestions: $e');
    }
  }

  Future<Either<String, List<FoodChainSuggestion>>> getUserChainSuggestions(
      String userId,
      {int limit = 20,
      int offset = 0}) async {
    try {
      final response = await apiClient.getUserChainSuggestions(
        limit: limit,
        offset: offset,
      );
      final suggestions = response.suggestions;

      // Update local cache
      for (final suggestion in suggestions) {
        final existing = await database.getSuggestionById(suggestion.id);
        if (existing != null) {
          await database
              .updateSuggestion(_suggestionToDatabase(suggestion, true));
        } else {
          await database.insertSuggestion(FoodChainSuggestionsCompanion(
            id: drift.Value(suggestion.id),
            userId: drift.Value(suggestion.userId),
            currentFoodName: drift.Value(suggestion.currentFoodName),
            suggestedFoodName: drift.Value(suggestion.suggestedFoodName),
            similarityScore: drift.Value(suggestion.similarityScore),
            reasoning: drift.Value(suggestion.reasoning),
            wasTried: drift.Value(suggestion.wasTried),
            wasLiked: drift.Value(suggestion.wasLiked),
            triedAt: drift.Value(suggestion.triedAt),
            feedback: drift.Value(suggestion.feedback),
            createdAt: drift.Value(suggestion.createdAt),
            syncedToServer: const drift.Value(true),
          ));
        }
      }

      return Right(suggestions);
    } catch (e) {
      // Fall back to local database
      try {
        final local =
            await database.getUserSuggestions(userId, limit: limit, offset: offset);
        return Right(local.map(_suggestionFromDatabase).toList());
      } catch (localError) {
        return Left('Failed to get chain suggestions: $e');
      }
    }
  }

  Future<Either<String, void>> recordChainFeedback(
      String suggestionId, RecordChainFeedbackRequest request) async {
    try {
      await apiClient.recordChainFeedback(suggestionId, request);

      // Update local cache
      final existing = await database.getSuggestionById(suggestionId);
      if (existing != null) {
        await database.updateSuggestion(
          existing.copyWith(
            wasTried: true,
            wasLiked: request.wasLiked,
            feedback: request.feedback,
            triedAt: DateTime.now(),
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to record feedback: $e');
    }
  }

  // Variation operations

  Future<Either<String, List<FoodVariation>>> getVariationIdeas(
      String foodName) async {
    try {
      final response = await apiClient.getVariationIdeas(foodName);
      final variations = response.variations;

      // Save to local database
      for (final variation in variations) {
        await database.insertVariation(FoodVariationsCompanion(
          id: drift.Value(variation.id),
          baseFoodName: drift.Value(variation.baseFoodName),
          variationType: drift.Value(variation.variationType),
          variationName: drift.Value(variation.variationName),
          description: drift.Value(variation.description),
          complexity: drift.Value(variation.complexity),
          createdAt: drift.Value(variation.createdAt),
          syncedToServer: const drift.Value(true),
        ));
      }

      return Right(variations);
    } catch (e) {
      // Fall back to local cache
      try {
        final local = await database.getVariationsForFood(foodName);
        if (local.isNotEmpty) {
          return Right(local.map(_variationFromDatabase).toList());
        }
      } catch (_) {}

      return Left('Failed to get variation ideas: $e');
    }
  }

  // Variety Analysis operations

  Future<Either<String, VarietyAnalysis>> getVarietyAnalysis() async {
    try {
      final analysis = await apiClient.getVarietyAnalysis();
      return Right(analysis);
    } catch (e) {
      return Left('Failed to get variety analysis: $e');
    }
  }

  // Nutrition Settings operations

  Future<Either<String, NutritionTrackingSettings>> getNutritionSettings(
      String userId) async {
    try {
      final settings = await apiClient.getNutritionSettings();

      // Update local cache
      final existing = await database.getNutritionSettings(userId);
      if (existing != null) {
        await database.updateNutritionSettings(
            _nutritionSettingsToDatabase(settings, true));
      } else {
        await database
            .insertNutritionSettings(NutritionTrackingSettingsTableCompanion(
          id: drift.Value(settings.id),
          userId: drift.Value(settings.userId),
          trackingEnabled: drift.Value(settings.trackingEnabled),
          showCalorieCounts: drift.Value(settings.showCalorieCounts),
          showMacros: drift.Value(settings.showMacros),
          showMicronutrients: drift.Value(settings.showMicronutrients),
          focusNutrients: drift.Value(jsonEncode(settings.focusNutrients)),
          showWeeklySummary: drift.Value(settings.showWeeklySummary),
          showDailySummary: drift.Value(settings.showDailySummary),
          reminderStyle: drift.Value(settings.reminderStyle),
          createdAt: drift.Value(settings.createdAt),
          updatedAt: drift.Value(settings.updatedAt),
          syncedToServer: const drift.Value(true),
        ));
      }

      return Right(settings);
    } catch (e) {
      // Fall back to local database
      try {
        final local = await database.getNutritionSettings(userId);
        if (local != null) {
          return Right(_nutritionSettingsFromDatabase(local));
        }
      } catch (_) {}

      return Left('Failed to get nutrition settings: $e');
    }
  }

  Future<Either<String, NutritionTrackingSettings>> updateNutritionSettings(
      UpdateNutritionSettingsRequest request, String userId) async {
    try {
      final settings = await apiClient.updateNutritionSettings(request);

      // Update local cache
      await database.updateNutritionSettings(
          _nutritionSettingsToDatabase(settings, true));

      return Right(settings);
    } catch (e) {
      return Left('Failed to update nutrition settings: $e');
    }
  }

  // Nutrition Insights operations

  Future<Either<String, List<NutritionInsight>>> getWeeklyInsights(
      String userId) async {
    try {
      final response = await apiClient.getWeeklyInsights();
      final insights = response.insights;

      // Update local cache
      for (final insight in insights) {
        final existing = await database.getInsightById(insight.id);
        if (existing != null) {
          await database.updateInsight(_insightToDatabase(insight, true));
        } else {
          await database.insertInsight(NutritionInsightsCompanion(
            id: drift.Value(insight.id),
            userId: drift.Value(insight.userId),
            weekStartDate: drift.Value(insight.weekStartDate),
            insightType: drift.Value(insight.insightType),
            message: drift.Value(insight.message),
            isDismissed: drift.Value(insight.isDismissed),
            createdAt: drift.Value(insight.createdAt),
            syncedToServer: const drift.Value(true),
          ));
        }
      }

      return Right(insights);
    } catch (e) {
      // Fall back to local database
      try {
        // Get current week start
        final now = DateTime.now();
        final weekday = now.weekday;
        final weekStart =
            now.subtract(Duration(days: weekday - 1)).copyWith(
                  hour: 0,
                  minute: 0,
                  second: 0,
                  millisecond: 0,
                  microsecond: 0,
                );

        final local = await database.getWeeklyInsights(userId, weekStart);
        if (local.isNotEmpty) {
          return Right(local.map(_insightFromDatabase).toList());
        }
      } catch (_) {}

      return Left('Failed to get weekly insights: $e');
    }
  }

  Future<Either<String, List<NutritionInsight>>> generateWeeklyInsights(
      String userId) async {
    try {
      final response = await apiClient.generateWeeklyInsights();
      final insights = response.insights;

      // Save to local database
      for (final insight in insights) {
        await database.insertInsight(NutritionInsightsCompanion(
          id: drift.Value(insight.id),
          userId: drift.Value(insight.userId),
          weekStartDate: drift.Value(insight.weekStartDate),
          insightType: drift.Value(insight.insightType),
          message: drift.Value(insight.message),
          isDismissed: drift.Value(insight.isDismissed),
          createdAt: drift.Value(insight.createdAt),
          syncedToServer: const drift.Value(true),
        ));
      }

      return Right(insights);
    } catch (e) {
      return Left('Failed to generate weekly insights: $e');
    }
  }

  Future<Either<String, void>> dismissInsight(String insightId) async {
    try {
      await apiClient.dismissInsight(insightId);

      // Update local cache
      await database.dismissInsight(insightId);

      return const Right(null);
    } catch (e) {
      return Left('Failed to dismiss insight: $e');
    }
  }

  // Rotation Schedule operations

  Future<Either<String, FoodRotationSchedule>> createRotationSchedule(
      CreateRotationScheduleRequest request) async {
    try {
      final schedule = await apiClient.createRotationSchedule(request);

      // Save to local database
      await database.insertSchedule(FoodRotationSchedulesCompanion(
        id: drift.Value(schedule.id),
        userId: drift.Value(schedule.userId),
        scheduleName: drift.Value(schedule.scheduleName),
        rotationDays: drift.Value(schedule.rotationDays),
        foods: drift.Value(
            jsonEncode(schedule.foods.map((f) => f.toJson()).toList())),
        isActive: drift.Value(schedule.isActive),
        createdAt: drift.Value(schedule.createdAt),
        updatedAt: drift.Value(schedule.updatedAt),
        syncedToServer: const drift.Value(true),
      ));

      return Right(schedule);
    } catch (e) {
      return Left('Failed to create rotation schedule: $e');
    }
  }

  Future<Either<String, List<FoodRotationSchedule>>> getRotationSchedules(
      String userId) async {
    try {
      final response = await apiClient.getRotationSchedules();
      final schedules = response.schedules;

      // Update local cache
      for (final schedule in schedules) {
        final existing = await database.getScheduleById(schedule.id);
        if (existing != null) {
          await database.updateSchedule(_scheduleToDatabase(schedule, true));
        } else {
          await database.insertSchedule(FoodRotationSchedulesCompanion(
            id: drift.Value(schedule.id),
            userId: drift.Value(schedule.userId),
            scheduleName: drift.Value(schedule.scheduleName),
            rotationDays: drift.Value(schedule.rotationDays),
            foods: drift.Value(
                jsonEncode(schedule.foods.map((f) => f.toJson()).toList())),
            isActive: drift.Value(schedule.isActive),
            createdAt: drift.Value(schedule.createdAt),
            updatedAt: drift.Value(schedule.updatedAt),
            syncedToServer: const drift.Value(true),
          ));
        }
      }

      return Right(schedules);
    } catch (e) {
      // Fall back to local database
      try {
        final local = await database.getUserSchedules(userId);
        return Right(local.map(_scheduleFromDatabase).toList());
      } catch (localError) {
        return Left('Failed to get rotation schedules: $e');
      }
    }
  }

  Future<Either<String, FoodRotationSchedule>> updateRotationSchedule(
      String scheduleId, UpdateRotationScheduleRequest request) async {
    try {
      final schedule =
          await apiClient.updateRotationSchedule(scheduleId, request);

      // Update local cache
      await database.updateSchedule(_scheduleToDatabase(schedule, true));

      return Right(schedule);
    } catch (e) {
      return Left('Failed to update rotation schedule: $e');
    }
  }

  Future<Either<String, void>> deleteRotationSchedule(String scheduleId) async {
    try {
      await apiClient.deleteRotationSchedule(scheduleId);

      // Delete from local database
      await database.deleteSchedule(scheduleId);

      return const Right(null);
    } catch (e) {
      return Left('Failed to delete rotation schedule: $e');
    }
  }

  // Helper methods to convert between database and model types

  FoodHyperfixation _hyperfixationFromDatabase(FoodHyperfixation dbRow) {
    return FoodHyperfixation(
      id: dbRow.id,
      userId: dbRow.userId,
      foodName: dbRow.foodName,
      startedAt: dbRow.startedAt,
      frequencyCount: dbRow.frequencyCount,
      peakFrequencyPerDay: dbRow.peakFrequencyPerDay,
      isActive: dbRow.isActive,
      endedAt: dbRow.endedAt,
      notes: dbRow.notes,
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
    );
  }

  FoodChainSuggestion _suggestionFromDatabase(FoodChainSuggestion dbRow) {
    return FoodChainSuggestion(
      id: dbRow.id,
      userId: dbRow.userId,
      currentFoodName: dbRow.currentFoodName,
      suggestedFoodName: dbRow.suggestedFoodName,
      similarityScore: dbRow.similarityScore,
      reasoning: dbRow.reasoning,
      wasTried: dbRow.wasTried,
      wasLiked: dbRow.wasLiked,
      triedAt: dbRow.triedAt,
      feedback: dbRow.feedback,
      createdAt: dbRow.createdAt,
    );
  }

  FoodChainSuggestion _suggestionToDatabase(
      FoodChainSuggestion suggestion, bool synced) {
    return FoodChainSuggestion(
      id: suggestion.id,
      userId: suggestion.userId,
      currentFoodName: suggestion.currentFoodName,
      suggestedFoodName: suggestion.suggestedFoodName,
      similarityScore: suggestion.similarityScore,
      reasoning: suggestion.reasoning,
      wasTried: suggestion.wasTried,
      wasLiked: suggestion.wasLiked,
      triedAt: suggestion.triedAt,
      feedback: suggestion.feedback,
      createdAt: suggestion.createdAt,
    );
  }

  FoodVariation _variationFromDatabase(FoodVariation dbRow) {
    return FoodVariation(
      id: dbRow.id,
      baseFoodName: dbRow.baseFoodName,
      variationType: dbRow.variationType,
      variationName: dbRow.variationName,
      description: dbRow.description,
      complexity: dbRow.complexity,
      createdAt: dbRow.createdAt,
    );
  }

  NutritionTrackingSettings _nutritionSettingsFromDatabase(
      NutritionTrackingSettingsTableData dbRow) {
    return NutritionTrackingSettings(
      id: dbRow.id,
      userId: dbRow.userId,
      trackingEnabled: dbRow.trackingEnabled,
      showCalorieCounts: dbRow.showCalorieCounts,
      showMacros: dbRow.showMacros,
      showMicronutrients: dbRow.showMicronutrients,
      focusNutrients: (jsonDecode(dbRow.focusNutrients) as List)
          .map((e) => e as String)
          .toList(),
      showWeeklySummary: dbRow.showWeeklySummary,
      showDailySummary: dbRow.showDailySummary,
      reminderStyle: dbRow.reminderStyle,
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
    );
  }

  NutritionTrackingSettingsTableData _nutritionSettingsToDatabase(
      NutritionTrackingSettings settings, bool synced) {
    return NutritionTrackingSettingsTableData(
      id: settings.id,
      userId: settings.userId,
      trackingEnabled: settings.trackingEnabled,
      showCalorieCounts: settings.showCalorieCounts,
      showMacros: settings.showMacros,
      showMicronutrients: settings.showMicronutrients,
      focusNutrients: jsonEncode(settings.focusNutrients),
      showWeeklySummary: settings.showWeeklySummary,
      showDailySummary: settings.showDailySummary,
      reminderStyle: settings.reminderStyle,
      createdAt: settings.createdAt,
      updatedAt: settings.updatedAt,
      syncedToServer: synced,
    );
  }

  NutritionInsight _insightFromDatabase(NutritionInsight dbRow) {
    return NutritionInsight(
      id: dbRow.id,
      userId: dbRow.userId,
      weekStartDate: dbRow.weekStartDate,
      insightType: dbRow.insightType,
      message: dbRow.message,
      isDismissed: dbRow.isDismissed,
      createdAt: dbRow.createdAt,
    );
  }

  NutritionInsight _insightToDatabase(NutritionInsight insight, bool synced) {
    return NutritionInsight(
      id: insight.id,
      userId: insight.userId,
      weekStartDate: insight.weekStartDate,
      insightType: insight.insightType,
      message: insight.message,
      isDismissed: insight.isDismissed,
      createdAt: insight.createdAt,
    );
  }

  FoodRotationSchedule _scheduleFromDatabase(FoodRotationSchedule dbRow) {
    return FoodRotationSchedule(
      id: dbRow.id,
      userId: dbRow.userId,
      scheduleName: dbRow.scheduleName,
      rotationDays: dbRow.rotationDays,
      foods: dbRow.foods,
      isActive: dbRow.isActive,
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
    );
  }

  FoodRotationSchedule _scheduleToDatabase(
      FoodRotationSchedule schedule, bool synced) {
    return FoodRotationSchedule(
      id: schedule.id,
      userId: schedule.userId,
      scheduleName: schedule.scheduleName,
      rotationDays: schedule.rotationDays,
      foods: schedule.foods,
      isActive: schedule.isActive,
      createdAt: schedule.createdAt,
      updatedAt: schedule.updatedAt,
    );
  }
}
