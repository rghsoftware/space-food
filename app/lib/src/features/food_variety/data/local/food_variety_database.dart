// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'food_variety_database.g.dart';

// Food Hyperfixations table
class FoodHyperfixations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get foodName => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get frequencyCount => integer()();
  RealColumn get peakFrequencyPerDay => real()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Food Chain Suggestions table
class FoodChainSuggestions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get currentFoodName => text()();
  TextColumn get suggestedFoodName => text()();
  RealColumn get similarityScore => real()();
  TextColumn get reasoning => text()();
  BoolColumn get wasTried => boolean()();
  BoolColumn get wasLiked => boolean().nullable()();
  DateTimeColumn get triedAt => dateTime().nullable()();
  TextColumn get feedback => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Food Variations table
class FoodVariations extends Table {
  TextColumn get id => text()();
  TextColumn get baseFoodName => text()();
  TextColumn get variationType => text()();
  TextColumn get variationName => text()();
  TextColumn get description => text().nullable()();
  IntColumn get complexity => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Nutrition Tracking Settings table
class NutritionTrackingSettingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  BoolColumn get trackingEnabled => boolean()();
  BoolColumn get showCalorieCounts => boolean()();
  BoolColumn get showMacros => boolean()();
  BoolColumn get showMicronutrients => boolean()();
  TextColumn get focusNutrients => text()(); // JSON array string
  BoolColumn get showWeeklySummary => boolean()();
  BoolColumn get showDailySummary => boolean()();
  TextColumn get reminderStyle => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'nutrition_tracking_settings';
}

// Nutrition Insights table
class NutritionInsights extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get weekStartDate => dateTime()();
  TextColumn get insightType => text()();
  TextColumn get message => text()();
  BoolColumn get isDismissed => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Food Rotation Schedules table
class FoodRotationSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get scheduleName => text()();
  IntColumn get rotationDays => integer()();
  TextColumn get foods => text()(); // JSON array string
  BoolColumn get isActive => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  FoodHyperfixations,
  FoodChainSuggestions,
  FoodVariations,
  NutritionTrackingSettingsTable,
  NutritionInsights,
  FoodRotationSchedules,
])
class FoodVarietyDatabase extends _$FoodVarietyDatabase {
  FoodVarietyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Food Hyperfixation operations
  Future<List<FoodHyperfixation>> getAllHyperfixations() =>
      select(foodHyperfixations).get();

  Future<List<FoodHyperfixation>> getActiveHyperfixations(String userId) =>
      (select(foodHyperfixations)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.isActive.equals(true))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
          .get();

  Future<FoodHyperfixation?> getHyperfixationById(String id) =>
      (select(foodHyperfixations)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertHyperfixation(FoodHyperfixationsCompanion hyperfixation) =>
      into(foodHyperfixations).insert(hyperfixation);

  Future<bool> updateHyperfixation(FoodHyperfixation hyperfixation) =>
      update(foodHyperfixations).replace(hyperfixation);

  Future<int> deleteHyperfixation(String id) =>
      (delete(foodHyperfixations)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<FoodHyperfixation>> getUnsyncedHyperfixations() =>
      (select(foodHyperfixations)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markHyperfixationSynced(String id) =>
      (update(foodHyperfixations)..where((tbl) => tbl.id.equals(id)))
          .write(const FoodHyperfixationsCompanion(
        syncedToServer: Value(true),
      ));

  // Food Chain Suggestion operations
  Future<List<FoodChainSuggestion>> getAllSuggestions() =>
      select(foodChainSuggestions).get();

  Future<List<FoodChainSuggestion>> getUserSuggestions(String userId,
      {int limit = 20, int offset = 0}) =>
      (select(foodChainSuggestions)
            ..where((tbl) => tbl.userId.equals(userId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<List<FoodChainSuggestion>> getSuggestionsForFood(
          String userId, String foodName) =>
      (select(foodChainSuggestions)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.currentFoodName.equals(foodName) &
                tbl.wasTried.equals(false))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.similarityScore)]))
          .get();

  Future<FoodChainSuggestion?> getSuggestionById(String id) =>
      (select(foodChainSuggestions)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertSuggestion(FoodChainSuggestionsCompanion suggestion) =>
      into(foodChainSuggestions).insert(suggestion);

  Future<bool> updateSuggestion(FoodChainSuggestion suggestion) =>
      update(foodChainSuggestions).replace(suggestion);

  Future<int> deleteSuggestion(String id) =>
      (delete(foodChainSuggestions)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<FoodChainSuggestion>> getUnsyncedSuggestions() =>
      (select(foodChainSuggestions)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markSuggestionSynced(String id) =>
      (update(foodChainSuggestions)..where((tbl) => tbl.id.equals(id)))
          .write(const FoodChainSuggestionsCompanion(
        syncedToServer: Value(true),
      ));

  // Food Variation operations
  Future<List<FoodVariation>> getAllVariations() =>
      select(foodVariations).get();

  Future<List<FoodVariation>> getVariationsForFood(String foodName) =>
      (select(foodVariations)
            ..where((tbl) => tbl.baseFoodName.equals(foodName))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.complexity)]))
          .get();

  Future<FoodVariation?> getVariationById(String id) =>
      (select(foodVariations)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertVariation(FoodVariationsCompanion variation) =>
      into(foodVariations).insert(variation);

  Future<bool> updateVariation(FoodVariation variation) =>
      update(foodVariations).replace(variation);

  Future<int> deleteVariation(String id) =>
      (delete(foodVariations)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<FoodVariation>> getUnsyncedVariations() =>
      (select(foodVariations)..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markVariationSynced(String id) =>
      (update(foodVariations)..where((tbl) => tbl.id.equals(id)))
          .write(const FoodVariationsCompanion(
        syncedToServer: Value(true),
      ));

  // Nutrition Settings operations
  Future<NutritionTrackingSettingsTableData?> getNutritionSettings(
          String userId) =>
      (select(nutritionTrackingSettingsTable)
            ..where((tbl) => tbl.userId.equals(userId)))
          .getSingleOrNull();

  Future<int> insertNutritionSettings(
          NutritionTrackingSettingsTableCompanion settings) =>
      into(nutritionTrackingSettingsTable).insert(settings);

  Future<bool> updateNutritionSettings(
          NutritionTrackingSettingsTableData settings) =>
      update(nutritionTrackingSettingsTable).replace(settings);

  Future<List<NutritionTrackingSettingsTableData>> getUnsyncedSettings() =>
      (select(nutritionTrackingSettingsTable)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markSettingsSynced(String id) =>
      (update(nutritionTrackingSettingsTable)..where((tbl) => tbl.id.equals(id)))
          .write(const NutritionTrackingSettingsTableCompanion(
        syncedToServer: Value(true),
      ));

  // Nutrition Insight operations
  Future<List<NutritionInsight>> getAllInsights() =>
      select(nutritionInsights).get();

  Future<List<NutritionInsight>> getWeeklyInsights(
          String userId, DateTime weekStart) =>
      (select(nutritionInsights)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.weekStartDate.equals(weekStart) &
                tbl.isDismissed.equals(false))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

  Future<NutritionInsight?> getInsightById(String id) =>
      (select(nutritionInsights)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertInsight(NutritionInsightsCompanion insight) =>
      into(nutritionInsights).insert(insight);

  Future<bool> updateInsight(NutritionInsight insight) =>
      update(nutritionInsights).replace(insight);

  Future<int> dismissInsight(String id) =>
      (update(nutritionInsights)..where((tbl) => tbl.id.equals(id)))
          .write(const NutritionInsightsCompanion(
        isDismissed: Value(true),
      ));

  Future<int> deleteInsight(String id) =>
      (delete(nutritionInsights)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<NutritionInsight>> getUnsyncedInsights() =>
      (select(nutritionInsights)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markInsightSynced(String id) =>
      (update(nutritionInsights)..where((tbl) => tbl.id.equals(id)))
          .write(const NutritionInsightsCompanion(
        syncedToServer: Value(true),
      ));

  // Rotation Schedule operations
  Future<List<FoodRotationSchedule>> getAllSchedules() =>
      select(foodRotationSchedules).get();

  Future<List<FoodRotationSchedule>> getUserSchedules(String userId) =>
      (select(foodRotationSchedules)
            ..where((tbl) => tbl.userId.equals(userId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

  Future<List<FoodRotationSchedule>> getActiveSchedules(String userId) =>
      (select(foodRotationSchedules)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.isActive.equals(true))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

  Future<FoodRotationSchedule?> getScheduleById(String id) =>
      (select(foodRotationSchedules)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertSchedule(FoodRotationSchedulesCompanion schedule) =>
      into(foodRotationSchedules).insert(schedule);

  Future<bool> updateSchedule(FoodRotationSchedule schedule) =>
      update(foodRotationSchedules).replace(schedule);

  Future<int> deleteSchedule(String id) =>
      (delete(foodRotationSchedules)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<FoodRotationSchedule>> getUnsyncedSchedules() =>
      (select(foodRotationSchedules)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markScheduleSynced(String id) =>
      (update(foodRotationSchedules)..where((tbl) => tbl.id.equals(id)))
          .write(const FoodRotationSchedulesCompanion(
        syncedToServer: Value(true),
      ));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'food_variety.sqlite'));
    return NativeDatabase(file);
  });
}
