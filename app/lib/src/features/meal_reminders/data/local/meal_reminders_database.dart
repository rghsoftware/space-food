/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'meal_reminders_database.g.dart';

/// Meal reminders table for offline storage
class MealReminders extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get scheduledTime => text()(); // "HH:MM:SS"
  IntColumn get preAlertMinutes => integer().withDefault(const Constant(15))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get daysOfWeek => text()(); // JSON array: "[0,1,2,3,4,5,6]"
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Meal logs table for offline storage
class MealLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get reminderId => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get scheduledFor => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get energyLevel => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Eating timeline settings table for offline storage
class EatingTimelineSettingsTable extends Table {
  @override
  String get tableName => 'eating_timeline_settings';

  TextColumn get userId => text()();
  IntColumn get dailyMealGoal => integer().withDefault(const Constant(3))();
  IntColumn get dailySnackGoal => integer().withDefault(const Constant(2))();
  BoolColumn get showStreak => boolean().withDefault(const Constant(true))();
  BoolColumn get showMissedMeals => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(tables: [
  MealReminders,
  MealLogs,
  EatingTimelineSettingsTable,
])
class MealRemindersDatabase extends _$MealRemindersDatabase {
  MealRemindersDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here
        },
      );

  // Meal Reminders Operations
  Future<List<MealReminder>> getAllReminders(String userId) {
    return (select(mealReminders)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.scheduledTime),
          ]))
        .get();
  }

  Future<MealReminder?> getReminderById(String id) {
    return (select(mealReminders)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertReminder(MealRemindersCompanion reminder) {
    return into(mealReminders).insert(reminder);
  }

  Future<bool> updateReminder(MealRemindersCompanion reminder) {
    return update(mealReminders).replace(reminder);
  }

  Future<int> deleteReminder(String id) {
    return (delete(mealReminders)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<MealReminder>> getUnsyncedReminders() {
    return (select(mealReminders)
          ..where((tbl) => tbl.syncedToServer.equals(false)))
        .get();
  }

  Future<int> markReminderSynced(String id) {
    return (update(mealReminders)..where((tbl) => tbl.id.equals(id)))
        .write(const MealRemindersCompanion(syncedToServer: Value(true)));
  }

  // Meal Logs Operations
  Future<List<MealLog>> getMealLogs(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(mealLogs)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.loggedAt.isBiggerOrEqualValue(startDate) &
              tbl.loggedAt.isSmallerOrEqualValue(endDate))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.loggedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertMealLog(MealLogsCompanion log) {
    return into(mealLogs).insert(log);
  }

  Future<List<MealLog>> getUnsyncedMealLogs() {
    return (select(mealLogs)..where((tbl) => tbl.syncedToServer.equals(false)))
        .get();
  }

  Future<int> markMealLogSynced(String id) {
    return (update(mealLogs)..where((tbl) => tbl.id.equals(id)))
        .write(const MealLogsCompanion(syncedToServer: Value(true)));
  }

  // Timeline Settings Operations
  Future<EatingTimelineSettingsTableData?> getTimelineSettings(
      String userId) {
    return (select(eatingTimelineSettingsTable)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdateTimelineSettings(
    EatingTimelineSettingsTableCompanion settings,
  ) {
    return into(eatingTimelineSettingsTable).insertOnConflictUpdate(settings);
  }

  Future<bool> markTimelineSettingsSynced(String userId) async {
    final rowsAffected = await (update(eatingTimelineSettingsTable)
          ..where((tbl) => tbl.userId.equals(userId)))
        .write(
      const EatingTimelineSettingsTableCompanion(syncedToServer: Value(true)),
    );
    return rowsAffected > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'meal_reminders.sqlite'));
    return NativeDatabase(file);
  });
}
