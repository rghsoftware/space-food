/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'energy_tracking_database.g.dart';

/// Energy snapshots table for offline storage
class EnergySnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get energyLevel => integer()();
  TextColumn get timeOfDay => text()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get context => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User energy patterns table for offline storage
class UserEnergyPatterns extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get timeOfDay => text()();
  IntColumn get dayOfWeek => integer()();
  IntColumn get typicalEnergyLevel => integer()();
  IntColumn get sampleCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Favorite meals table for offline storage
class FavoriteMeals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get recipeId => text().nullable()();
  TextColumn get mealName => text()();
  IntColumn get energyLevel => integer().nullable()();
  TextColumn get typicalTimeOfDay => text().nullable()();
  IntColumn get frequencyScore => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastEaten => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  EnergySnapshots,
  UserEnergyPatterns,
  FavoriteMeals,
])
class EnergyTrackingDatabase extends _$EnergyTrackingDatabase {
  EnergyTrackingDatabase() : super(_openConnection());

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

  // Energy Snapshots Operations

  Future<List<EnergySnapshot>> getAllSnapshots(String userId, {int? days}) {
    final query = select(energySnapshots)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ]);

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      query.where((tbl) => tbl.recordedAt.isBiggerOrEqualValue(cutoffDate));
    }

    return query.get();
  }

  Future<int> insertSnapshot(EnergySnapshotsCompanion snapshot) {
    return into(energySnapshots).insert(snapshot);
  }

  Future<List<EnergySnapshot>> getUnsyncedSnapshots() {
    return (select(energySnapshots)
          ..where((tbl) => tbl.syncedToServer.equals(false)))
        .get();
  }

  Future<int> markSnapshotSynced(String id) {
    return (update(energySnapshots)..where((tbl) => tbl.id.equals(id)))
        .write(const EnergySnapshotsCompanion(syncedToServer: Value(true)));
  }

  // Energy Patterns Operations

  Future<List<UserEnergyPattern>> getAllPatterns(String userId) {
    return (select(userEnergyPatterns)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.dayOfWeek),
          ]))
        .get();
  }

  Future<UserEnergyPattern?> getPattern(
    String userId,
    String timeOfDay,
    int dayOfWeek,
  ) {
    return (select(userEnergyPatterns)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.timeOfDay.equals(timeOfDay) &
              tbl.dayOfWeek.equals(dayOfWeek)))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdatePattern(UserEnergyPatternsCompanion pattern) {
    return into(userEnergyPatterns).insertOnConflictUpdate(pattern);
  }

  // Favorite Meals Operations

  Future<List<FavoriteMeal>> getAllFavoriteMeals(String userId) {
    return (select(favoriteMeals)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.frequencyScore, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<FavoriteMeal>> getFavoriteMealsByEnergy(
    String userId,
    int? maxEnergyLevel,
    String? timeOfDay,
  ) {
    var query = select(favoriteMeals)..where((tbl) => tbl.userId.equals(userId));

    if (maxEnergyLevel != null) {
      query = query
        ..where((tbl) =>
            tbl.energyLevel.isNull() |
            tbl.energyLevel.isSmallerOrEqualValue(maxEnergyLevel));
    }

    if (timeOfDay != null) {
      query = query
        ..where((tbl) =>
            tbl.typicalTimeOfDay.isNull() |
            tbl.typicalTimeOfDay.equals(timeOfDay));
    }

    query = query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.frequencyScore, mode: OrderingMode.desc),
      ]);

    return query.get();
  }

  Future<FavoriteMeal?> getFavoriteMealById(String id) {
    return (select(favoriteMeals)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertFavoriteMeal(FavoriteMealsCompanion meal) {
    return into(favoriteMeals).insert(meal);
  }

  Future<bool> updateFavoriteMeal(FavoriteMealsCompanion meal) {
    return update(favoriteMeals).replace(meal);
  }

  Future<int> incrementMealFrequency(String id) {
    return customUpdate(
      'UPDATE favorite_meals SET frequency_score = frequency_score + 1, last_eaten = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withDateTime(DateTime.now()),
        Variable.withDateTime(DateTime.now()),
        Variable.withString(id),
      ],
      updates: {favoriteMeals},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> deleteFavoriteMeal(String id) {
    return (delete(favoriteMeals)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<FavoriteMeal>> getUnsyncedMeals() {
    return (select(favoriteMeals)
          ..where((tbl) => tbl.syncedToServer.equals(false)))
        .get();
  }

  Future<int> markMealSynced(String id) {
    return (update(favoriteMeals)..where((tbl) => tbl.id.equals(id)))
        .write(const FavoriteMealsCompanion(syncedToServer: Value(true)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'energy_tracking.sqlite'));
    return NativeDatabase(file);
  });
}
