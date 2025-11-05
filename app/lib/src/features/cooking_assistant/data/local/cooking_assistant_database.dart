// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'cooking_assistant_database.g.dart';

// Recipe Breakdowns table
class RecipeBreakdowns extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text()();
  TextColumn get userId => text().nullable()();
  IntColumn get granularityLevel => integer()();
  IntColumn get energyLevel => integer().nullable()();
  TextColumn get breakdownData => text()(); // JSON string
  TextColumn get aiProvider => text()();
  TextColumn get aiModel => text()();
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  IntColumn get useCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Cooking Sessions table
class CookingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get recipeId => text()();
  TextColumn get breakdownId => text().nullable()();
  TextColumn get mealLogId => text().nullable()();
  TextColumn get status => text()();
  IntColumn get currentStepIndex => integer()();
  IntColumn get totalSteps => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  DateTimeColumn get resumedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get abandonedAt => dateTime().nullable()();
  IntColumn get totalPauseDurationSeconds => integer()();
  IntColumn get energyLevelAtStart => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get bodyDoublingRoomId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Cooking Step Completions table
class CookingStepCompletions extends Table {
  TextColumn get id => text()();
  TextColumn get cookingSessionId => text()();
  IntColumn get stepIndex => integer()();
  TextColumn get stepText => text()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get timeTakenSeconds => integer().nullable()();
  BoolColumn get skipped => boolean()();
  IntColumn get difficultyRating => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Cooking Timers table
class CookingTimers extends Table {
  TextColumn get id => text()();
  TextColumn get cookingSessionId => text()();
  IntColumn get stepIndex => integer().nullable()();
  TextColumn get name => text()();
  IntColumn get durationSeconds => integer()();
  IntColumn get remainingSeconds => integer()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  DateTimeColumn get resumedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  IntColumn get totalPauseDurationSeconds => integer()();
  BoolColumn get notificationSent => boolean()();
  DateTimeColumn get notificationSentAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Body Doubling Rooms table
class BodyDoublingRooms extends Table {
  TextColumn get id => text()();
  TextColumn get createdBy => text()();
  TextColumn get roomName => text()();
  TextColumn get roomCode => text()();
  TextColumn get description => text().nullable()();
  IntColumn get maxParticipants => integer()();
  BoolColumn get isPublic => boolean()();
  TextColumn get status => text()();
  DateTimeColumn get scheduledStartTime => dateTime().nullable()();
  DateTimeColumn get actualStartTime => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Body Doubling Participants table
class BodyDoublingParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get roomId => text()();
  TextColumn get userId => text()();
  TextColumn get cookingSessionId => text().nullable()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get leftAt => dateTime().nullable()();
  BoolColumn get isActive => boolean()();
  TextColumn get recipeName => text().nullable()();
  TextColumn get currentStep => text().nullable()();
  IntColumn get energyLevel => integer().nullable()();
  DateTimeColumn get lastActivityAt => dateTime()();
  IntColumn get messageCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  RecipeBreakdowns,
  CookingSessions,
  CookingStepCompletions,
  CookingTimers,
  BodyDoublingRooms,
  BodyDoublingParticipants,
])
class CookingAssistantDatabase extends _$CookingAssistantDatabase {
  CookingAssistantDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Recipe Breakdown operations
  Future<List<RecipeBreakdown>> getAllBreakdowns() =>
      select(recipeBreakdowns).get();

  Future<RecipeBreakdown?> getBreakdownById(String id) =>
      (select(recipeBreakdowns)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<List<RecipeBreakdown>> getBreakdownsByRecipeId(String recipeId) =>
      (select(recipeBreakdowns)..where((tbl) => tbl.recipeId.equals(recipeId)))
          .get();

  Future<int> insertBreakdown(RecipeBreakdownsCompanion breakdown) =>
      into(recipeBreakdowns).insert(breakdown);

  Future<bool> updateBreakdown(RecipeBreakdown breakdown) =>
      update(recipeBreakdowns).replace(breakdown);

  Future<int> deleteBreakdown(String id) =>
      (delete(recipeBreakdowns)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<RecipeBreakdown>> getUnsyncedBreakdowns() =>
      (select(recipeBreakdowns)..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markBreakdownSynced(String id) =>
      (update(recipeBreakdowns)..where((tbl) => tbl.id.equals(id)))
          .write(const RecipeBreakdownsCompanion(
        syncedToServer: Value(true),
      ));

  // Cooking Session operations
  Future<List<CookingSession>> getAllSessions() => select(cookingSessions).get();

  Future<CookingSession?> getSessionById(String id) =>
      (select(cookingSessions)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<List<CookingSession>> getActiveSessions() =>
      (select(cookingSessions)
            ..where((tbl) =>
                tbl.status.equals('active') | tbl.status.equals('paused'))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
          .get();

  Future<int> insertSession(CookingSessionsCompanion session) =>
      into(cookingSessions).insert(session);

  Future<bool> updateSession(CookingSession session) =>
      update(cookingSessions).replace(session);

  Future<int> deleteSession(String id) =>
      (delete(cookingSessions)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<CookingSession>> getUnsyncedSessions() =>
      (select(cookingSessions)..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markSessionSynced(String id) =>
      (update(cookingSessions)..where((tbl) => tbl.id.equals(id)))
          .write(const CookingSessionsCompanion(
        syncedToServer: Value(true),
      ));

  // Step Completion operations
  Future<List<CookingStepCompletion>> getSessionCompletions(
          String sessionId) =>
      (select(cookingStepCompletions)
            ..where((tbl) => tbl.cookingSessionId.equals(sessionId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.stepIndex)]))
          .get();

  Future<int> insertCompletion(CookingStepCompletionsCompanion completion) =>
      into(cookingStepCompletions).insert(completion);

  Future<bool> updateCompletion(CookingStepCompletion completion) =>
      update(cookingStepCompletions).replace(completion);

  Future<List<CookingStepCompletion>> getUnsyncedCompletions() =>
      (select(cookingStepCompletions)
            ..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markCompletionSynced(String id) =>
      (update(cookingStepCompletions)..where((tbl) => tbl.id.equals(id)))
          .write(const CookingStepCompletionsCompanion(
        syncedToServer: Value(true),
      ));

  // Timer operations
  Future<List<CookingTimer>> getSessionTimers(String sessionId) =>
      (select(cookingTimers)
            ..where((tbl) => tbl.cookingSessionId.equals(sessionId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

  Future<CookingTimer?> getTimerById(String id) =>
      (select(cookingTimers)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTimer(CookingTimersCompanion timer) =>
      into(cookingTimers).insert(timer);

  Future<bool> updateTimer(CookingTimer timer) =>
      update(cookingTimers).replace(timer);

  Future<int> deleteTimer(String id) =>
      (delete(cookingTimers)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<CookingTimer>> getUnsyncedTimers() =>
      (select(cookingTimers)..where((tbl) => tbl.syncedToServer.equals(false)))
          .get();

  Future<int> markTimerSynced(String id) =>
      (update(cookingTimers)..where((tbl) => tbl.id.equals(id)))
          .write(const CookingTimersCompanion(
        syncedToServer: Value(true),
      ));

  // Body Doubling Room operations
  Future<List<BodyDoublingRoom>> getActiveRooms() =>
      (select(bodyDoublingRooms)
            ..where((tbl) => tbl.status.equals('active'))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

  Future<BodyDoublingRoom?> getRoomById(String id) =>
      (select(bodyDoublingRooms)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<BodyDoublingRoom?> getRoomByCode(String code) =>
      (select(bodyDoublingRooms)..where((tbl) => tbl.roomCode.equals(code)))
          .getSingleOrNull();

  Future<int> insertRoom(BodyDoublingRoomsCompanion room) =>
      into(bodyDoublingRooms).insert(room);

  Future<bool> updateRoom(BodyDoublingRoom room) =>
      update(bodyDoublingRooms).replace(room);

  // Participant operations
  Future<List<BodyDoublingParticipant>> getRoomParticipants(String roomId) =>
      (select(bodyDoublingParticipants)
            ..where((tbl) =>
                tbl.roomId.equals(roomId) & tbl.isActive.equals(true))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.joinedAt)]))
          .get();

  Future<int> insertParticipant(BodyDoublingParticipantsCompanion participant) =>
      into(bodyDoublingParticipants).insert(participant);

  Future<bool> updateParticipant(BodyDoublingParticipant participant) =>
      update(bodyDoublingParticipants).replace(participant);

  Future<int> leaveRoom(String roomId, String userId) =>
      (update(bodyDoublingParticipants)
            ..where((tbl) =>
                tbl.roomId.equals(roomId) & tbl.userId.equals(userId)))
          .write(BodyDoublingParticipantsCompanion(
        isActive: const Value(false),
        leftAt: Value(DateTime.now()),
      ));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cooking_assistant.sqlite'));
    return NativeDatabase(file);
  });
}
