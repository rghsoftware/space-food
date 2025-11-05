// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:either_dart/either.dart';
import '../local/cooking_assistant_database.dart';
import '../remote/cooking_assistant_api_client.dart';
import '../models/recipe_breakdown.dart';
import '../models/cooking_session.dart';
import '../models/cooking_timer.dart';
import '../models/body_doubling_room.dart';

class CookingAssistantRepository {
  final CookingAssistantApiClient apiClient;
  final CookingAssistantDatabase database;

  CookingAssistantRepository({
    required this.apiClient,
    required this.database,
  });

  // Recipe Breakdown operations

  Future<Either<String, RecipeBreakdown>> generateBreakdown(
    GenerateBreakdownRequest request,
  ) async {
    try {
      final breakdown = await apiClient.generateBreakdown(request);

      // Save to local database
      await database.insertBreakdown(RecipeBreakdownsCompanion(
        id: drift.Value(breakdown.id),
        recipeId: drift.Value(breakdown.recipeId),
        userId: drift.Value(breakdown.userId),
        granularityLevel: drift.Value(breakdown.granularityLevel),
        energyLevel: drift.Value(breakdown.energyLevel),
        breakdownData: drift.Value(jsonEncode(breakdown.breakdownData.toJson())),
        aiProvider: drift.Value(breakdown.aiProvider),
        aiModel: drift.Value(breakdown.aiModel),
        generatedAt: drift.Value(breakdown.generatedAt),
        lastUsedAt: drift.Value(breakdown.lastUsedAt),
        useCount: drift.Value(breakdown.useCount),
        createdAt: drift.Value(breakdown.createdAt),
        updatedAt: drift.Value(breakdown.updatedAt),
        syncedToServer: const drift.Value(true),
      ));

      return Right(breakdown);
    } catch (e) {
      return Left('Failed to generate breakdown: $e');
    }
  }

  Future<Either<String, RecipeBreakdown>> getBreakdown(
    String recipeId, {
    int? granularity,
    int? energyLevel,
  }) async {
    try {
      // Try to get from API first
      final breakdown = await apiClient.getBreakdown(
        recipeId,
        granularity: granularity,
        energyLevel: energyLevel,
      );

      // Update local cache
      await database.insertBreakdown(RecipeBreakdownsCompanion(
        id: drift.Value(breakdown.id),
        recipeId: drift.Value(breakdown.recipeId),
        userId: drift.Value(breakdown.userId),
        granularityLevel: drift.Value(breakdown.granularityLevel),
        energyLevel: drift.Value(breakdown.energyLevel),
        breakdownData: drift.Value(jsonEncode(breakdown.breakdownData.toJson())),
        aiProvider: drift.Value(breakdown.aiProvider),
        aiModel: drift.Value(breakdown.aiModel),
        generatedAt: drift.Value(breakdown.generatedAt),
        lastUsedAt: drift.Value(breakdown.lastUsedAt),
        useCount: drift.Value(breakdown.useCount),
        createdAt: drift.Value(breakdown.createdAt),
        updatedAt: drift.Value(breakdown.updatedAt),
        syncedToServer: const drift.Value(true),
      ));

      return Right(breakdown);
    } catch (e) {
      // If API fails, try to get from local database
      final localBreakdowns = await database.getBreakdownsByRecipeId(recipeId);
      if (localBreakdowns.isNotEmpty) {
        // Find matching breakdown by granularity and energy level
        for (final local in localBreakdowns) {
          if ((granularity == null || local.granularityLevel == granularity) &&
              (energyLevel == null || local.energyLevel == energyLevel)) {
            return Right(_breakdownFromDatabase(local));
          }
        }
        // If no exact match, return first one
        return Right(_breakdownFromDatabase(localBreakdowns.first));
      }

      return Left('Failed to get breakdown: $e');
    }
  }

  // Cooking Session operations

  Future<Either<String, CookingSession>> startCookingSession(
    StartCookingSessionRequest request,
  ) async {
    try {
      final session = await apiClient.startCookingSession(request);

      // Save to local database
      await database.insertSession(CookingSessionsCompanion(
        id: drift.Value(session.id),
        userId: drift.Value(session.userId),
        recipeId: drift.Value(session.recipeId),
        breakdownId: drift.Value(session.breakdownId),
        mealLogId: drift.Value(session.mealLogId),
        status: drift.Value(session.status),
        currentStepIndex: drift.Value(session.currentStepIndex),
        totalSteps: drift.Value(session.totalSteps),
        startedAt: drift.Value(session.startedAt),
        totalPauseDurationSeconds: drift.Value(session.totalPauseDurationSeconds),
        energyLevelAtStart: drift.Value(session.energyLevelAtStart),
        notes: drift.Value(session.notes),
        bodyDoublingRoomId: drift.Value(session.bodyDoublingRoomId),
        createdAt: drift.Value(session.createdAt),
        updatedAt: drift.Value(session.updatedAt),
        syncedToServer: const drift.Value(true),
      ));

      return Right(session);
    } catch (e) {
      return Left('Failed to start cooking session: $e');
    }
  }

  Future<Either<String, CookingSession>> getCookingSession(
      String sessionId) async {
    try {
      final session = await apiClient.getCookingSession(sessionId);

      // Update local database
      final existingSession = await database.getSessionById(sessionId);
      if (existingSession != null) {
        await database.updateSession(_sessionToDatabase(session, true));
      } else {
        await database.insertSession(_sessionToCompanion(session, true));
      }

      return Right(session);
    } catch (e) {
      // Try to get from local database
      final localSession = await database.getSessionById(sessionId);
      if (localSession != null) {
        return Right(_sessionFromDatabase(localSession));
      }

      return Left('Failed to get cooking session: $e');
    }
  }

  Future<Either<String, List<CookingSession>>> getUserSessions({
    int? limit,
    int? offset,
  }) async {
    try {
      final sessions =
          await apiClient.getUserSessions(limit: limit, offset: offset);

      // Update local cache
      for (final session in sessions) {
        final existing = await database.getSessionById(session.id);
        if (existing != null) {
          await database.updateSession(_sessionToDatabase(session, true));
        } else {
          await database.insertSession(_sessionToCompanion(session, true));
        }
      }

      return Right(sessions);
    } catch (e) {
      // Return from local database
      final localSessions = await database.getAllSessions();
      if (localSessions.isNotEmpty) {
        return Right(
            localSessions.map((s) => _sessionFromDatabase(s)).toList());
      }

      return Left('Failed to get user sessions: $e');
    }
  }

  Future<Either<String, void>> updateProgress(
    String sessionId,
    UpdateSessionProgressRequest request,
  ) async {
    try {
      await apiClient.updateProgress(sessionId, request);

      // Update local database
      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          currentStepIndex: request.currentStepIndex,
          notes: request.notes,
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      // Queue for sync when online
      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          currentStepIndex: request.currentStepIndex,
          notes: request.notes,
          updatedAt: DateTime.now(),
          syncedToServer: false,
        ));
        return const Right(null);
      }

      return Left('Failed to update progress: $e');
    }
  }

  Future<Either<String, void>> pauseSession(String sessionId) async {
    try {
      await apiClient.pauseSession(sessionId);

      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          status: 'paused',
          pausedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to pause session: $e');
    }
  }

  Future<Either<String, void>> resumeSession(String sessionId) async {
    try {
      await apiClient.resumeSession(sessionId);

      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          status: 'active',
          resumedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to resume session: $e');
    }
  }

  Future<Either<String, void>> completeSession(String sessionId) async {
    try {
      await apiClient.completeSession(sessionId);

      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          status: 'completed',
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to complete session: $e');
    }
  }

  Future<Either<String, void>> abandonSession(String sessionId) async {
    try {
      await apiClient.abandonSession(sessionId);

      final session = await database.getSessionById(sessionId);
      if (session != null) {
        await database.updateSession(session.copyWith(
          status: 'abandoned',
          abandonedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to abandon session: $e');
    }
  }

  Future<Either<String, void>> completeStep(
    String sessionId,
    CompleteStepRequest request,
  ) async {
    try {
      await apiClient.completeStep(sessionId, request);

      // Save to local database
      await database.insertCompletion(CookingStepCompletionsCompanion(
        id: drift.Value(DateTime.now().toIso8601String()),
        cookingSessionId: drift.Value(sessionId),
        stepIndex: drift.Value(request.stepIndex),
        stepText: drift.Value(request.stepText),
        completedAt: drift.Value(DateTime.now()),
        timeTakenSeconds: drift.Value(request.timeTakenSeconds),
        skipped: drift.Value(request.skipped),
        difficultyRating: drift.Value(request.difficultyRating),
        notes: drift.Value(request.notes),
        createdAt: drift.Value(DateTime.now()),
        syncedToServer: const drift.Value(true),
      ));

      return const Right(null);
    } catch (e) {
      return Left('Failed to complete step: $e');
    }
  }

  // Timer operations

  Future<Either<String, CookingTimer>> createTimer(
    String sessionId,
    CreateTimerRequest request,
  ) async {
    try {
      final timer = await apiClient.createTimer(sessionId, request);

      // Save to local database
      await database.insertTimer(_timerToCompanion(timer, true));

      return Right(timer);
    } catch (e) {
      return Left('Failed to create timer: $e');
    }
  }

  Future<Either<String, List<CookingTimer>>> getSessionTimers(
      String sessionId) async {
    try {
      final timers = await apiClient.getSessionTimers(sessionId);

      // Update local cache
      for (final timer in timers) {
        final existing = await database.getTimerById(timer.id);
        if (existing != null) {
          await database.updateTimer(_timerToDatabase(timer, true));
        } else {
          await database.insertTimer(_timerToCompanion(timer, true));
        }
      }

      return Right(timers);
    } catch (e) {
      // Return from local database
      final localTimers = await database.getSessionTimers(sessionId);
      if (localTimers.isNotEmpty) {
        return Right(localTimers.map((t) => _timerFromDatabase(t)).toList());
      }

      return Left('Failed to get session timers: $e');
    }
  }

  Future<Either<String, void>> pauseTimer(String timerId) async {
    try {
      await apiClient.pauseTimer(timerId);

      final timer = await database.getTimerById(timerId);
      if (timer != null) {
        await database.updateTimer(timer.copyWith(
          status: 'paused',
          pausedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to pause timer: $e');
    }
  }

  Future<Either<String, void>> resumeTimer(String timerId) async {
    try {
      await apiClient.resumeTimer(timerId);

      final timer = await database.getTimerById(timerId);
      if (timer != null) {
        await database.updateTimer(timer.copyWith(
          status: 'running',
          resumedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to resume timer: $e');
    }
  }

  Future<Either<String, void>> completeTimer(String timerId) async {
    try {
      await apiClient.completeTimer(timerId);

      final timer = await database.getTimerById(timerId);
      if (timer != null) {
        await database.updateTimer(timer.copyWith(
          status: 'completed',
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to complete timer: $e');
    }
  }

  Future<Either<String, void>> cancelTimer(String timerId) async {
    try {
      await apiClient.cancelTimer(timerId);

      final timer = await database.getTimerById(timerId);
      if (timer != null) {
        await database.updateTimer(timer.copyWith(
          status: 'cancelled',
          cancelledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left('Failed to cancel timer: $e');
    }
  }

  // Body Doubling Room operations

  Future<Either<String, BodyDoublingRoom>> createRoom(
    CreateBodyDoublingRoomRequest request,
  ) async {
    try {
      final room = await apiClient.createRoom(request);

      // Save to local database
      await database.insertRoom(BodyDoublingRoomsCompanion(
        id: drift.Value(room.id),
        createdBy: drift.Value(room.createdBy),
        roomName: drift.Value(room.roomName),
        roomCode: drift.Value(room.roomCode),
        description: drift.Value(room.description),
        maxParticipants: drift.Value(room.maxParticipants),
        isPublic: drift.Value(room.isPublic),
        status: drift.Value(room.status),
        scheduledStartTime: drift.Value(room.scheduledStartTime),
        actualStartTime: drift.Value(room.actualStartTime),
        endedAt: drift.Value(room.endedAt),
        createdAt: drift.Value(room.createdAt),
        updatedAt: drift.Value(room.updatedAt),
        syncedToServer: const drift.Value(true),
      ));

      return Right(room);
    } catch (e) {
      return Left('Failed to create room: $e');
    }
  }

  Future<Either<String, BodyDoublingRoom>> joinRoom(
    JoinBodyDoublingRoomRequest request,
  ) async {
    try {
      final room = await apiClient.joinRoom(request);

      // Update local database
      final existing = await database.getRoomById(room.id);
      if (existing != null) {
        await database.updateRoom(_roomToDatabase(room));
      } else {
        await database.insertRoom(_roomToCompanion(room));
      }

      return Right(room);
    } catch (e) {
      return Left('Failed to join room: $e');
    }
  }

  Future<Either<String, void>> leaveRoom(String roomId) async {
    try {
      await apiClient.leaveRoom(roomId);
      return const Right(null);
    } catch (e) {
      return Left('Failed to leave room: $e');
    }
  }

  Future<Either<String, BodyDoublingRoom>> getRoom(String roomId) async {
    try {
      final room = await apiClient.getRoom(roomId);

      // Update local cache
      final existing = await database.getRoomById(roomId);
      if (existing != null) {
        await database.updateRoom(_roomToDatabase(room));
      } else {
        await database.insertRoom(_roomToCompanion(room));
      }

      return Right(room);
    } catch (e) {
      // Try to get from local database
      final localRoom = await database.getRoomById(roomId);
      if (localRoom != null) {
        return Right(_roomFromDatabase(localRoom));
      }

      return Left('Failed to get room: $e');
    }
  }

  Future<Either<String, List<BodyDoublingParticipant>>> getRoomParticipants(
      String roomId) async {
    try {
      final participants = await apiClient.getRoomParticipants(roomId);

      // Update local cache
      for (final participant in participants) {
        await database.insertParticipant(_participantToCompanion(participant));
      }

      return Right(participants);
    } catch (e) {
      // Return from local database
      final localParticipants = await database.getRoomParticipants(roomId);
      if (localParticipants.isNotEmpty) {
        return Right(localParticipants
            .map((p) => _participantFromDatabase(p))
            .toList());
      }

      return Left('Failed to get room participants: $e');
    }
  }

  Future<Either<String, List<BodyDoublingRoom>>> getPublicRooms({
    int? limit,
    int? offset,
  }) async {
    try {
      final rooms =
          await apiClient.getPublicRooms(limit: limit, offset: offset);

      // Update local cache
      for (final room in rooms) {
        final existing = await database.getRoomById(room.id);
        if (existing != null) {
          await database.updateRoom(_roomToDatabase(room));
        } else {
          await database.insertRoom(_roomToCompanion(room));
        }
      }

      return Right(rooms);
    } catch (e) {
      // Return from local database
      final localRooms = await database.getActiveRooms();
      if (localRooms.isNotEmpty) {
        return Right(localRooms.map((r) => _roomFromDatabase(r)).toList());
      }

      return Left('Failed to get public rooms: $e');
    }
  }

  Future<Either<String, void>> updateParticipantActivity(
    String roomId,
    UpdateParticipantActivityRequest request,
  ) async {
    try {
      await apiClient.updateParticipantActivity(roomId, request);
      return const Right(null);
    } catch (e) {
      return Left('Failed to update participant activity: $e');
    }
  }

  // Helper methods to convert between database and model objects

  RecipeBreakdown _breakdownFromDatabase(RecipeBreakdown dbBreakdown) {
    return dbBreakdown; // Already in the correct format
  }

  CookingSession _sessionFromDatabase(CookingSession dbSession) {
    return dbSession; // Already in the correct format
  }

  CookingSession _sessionToDatabase(CookingSession session, bool synced) {
    return session; // Already in the correct format
  }

  CookingSessionsCompanion _sessionToCompanion(
      CookingSession session, bool synced) {
    return CookingSessionsCompanion(
      id: drift.Value(session.id),
      userId: drift.Value(session.userId),
      recipeId: drift.Value(session.recipeId),
      breakdownId: drift.Value(session.breakdownId),
      mealLogId: drift.Value(session.mealLogId),
      status: drift.Value(session.status),
      currentStepIndex: drift.Value(session.currentStepIndex),
      totalSteps: drift.Value(session.totalSteps),
      startedAt: drift.Value(session.startedAt),
      pausedAt: drift.Value(session.pausedAt),
      resumedAt: drift.Value(session.resumedAt),
      completedAt: drift.Value(session.completedAt),
      abandonedAt: drift.Value(session.abandonedAt),
      totalPauseDurationSeconds: drift.Value(session.totalPauseDurationSeconds),
      energyLevelAtStart: drift.Value(session.energyLevelAtStart),
      notes: drift.Value(session.notes),
      bodyDoublingRoomId: drift.Value(session.bodyDoublingRoomId),
      createdAt: drift.Value(session.createdAt),
      updatedAt: drift.Value(session.updatedAt),
      syncedToServer: drift.Value(synced),
    );
  }

  CookingTimer _timerFromDatabase(CookingTimer dbTimer) {
    return dbTimer; // Already in the correct format
  }

  CookingTimer _timerToDatabase(CookingTimer timer, bool synced) {
    return timer; // Already in the correct format
  }

  CookingTimersCompanion _timerToCompanion(CookingTimer timer, bool synced) {
    return CookingTimersCompanion(
      id: drift.Value(timer.id),
      cookingSessionId: drift.Value(timer.cookingSessionId),
      stepIndex: drift.Value(timer.stepIndex),
      name: drift.Value(timer.name),
      durationSeconds: drift.Value(timer.durationSeconds),
      remainingSeconds: drift.Value(timer.remainingSeconds),
      status: drift.Value(timer.status),
      startedAt: drift.Value(timer.startedAt),
      pausedAt: drift.Value(timer.pausedAt),
      resumedAt: drift.Value(timer.resumedAt),
      completedAt: drift.Value(timer.completedAt),
      cancelledAt: drift.Value(timer.cancelledAt),
      totalPauseDurationSeconds: drift.Value(timer.totalPauseDurationSeconds),
      notificationSent: drift.Value(timer.notificationSent),
      notificationSentAt: drift.Value(timer.notificationSentAt),
      createdAt: drift.Value(timer.createdAt),
      updatedAt: drift.Value(timer.updatedAt),
      syncedToServer: drift.Value(synced),
    );
  }

  BodyDoublingRoom _roomFromDatabase(BodyDoublingRoom dbRoom) {
    return dbRoom; // Already in the correct format
  }

  BodyDoublingRoom _roomToDatabase(BodyDoublingRoom room) {
    return room; // Already in the correct format
  }

  BodyDoublingRoomsCompanion _roomToCompanion(BodyDoublingRoom room) {
    return BodyDoublingRoomsCompanion(
      id: drift.Value(room.id),
      createdBy: drift.Value(room.createdBy),
      roomName: drift.Value(room.roomName),
      roomCode: drift.Value(room.roomCode),
      description: drift.Value(room.description),
      maxParticipants: drift.Value(room.maxParticipants),
      isPublic: drift.Value(room.isPublic),
      status: drift.Value(room.status),
      scheduledStartTime: drift.Value(room.scheduledStartTime),
      actualStartTime: drift.Value(room.actualStartTime),
      endedAt: drift.Value(room.endedAt),
      createdAt: drift.Value(room.createdAt),
      updatedAt: drift.Value(room.updatedAt),
      syncedToServer: const drift.Value(true),
    );
  }

  BodyDoublingParticipant _participantFromDatabase(
      BodyDoublingParticipant dbParticipant) {
    return dbParticipant; // Already in the correct format
  }

  BodyDoublingParticipantsCompanion _participantToCompanion(
      BodyDoublingParticipant participant) {
    return BodyDoublingParticipantsCompanion(
      id: drift.Value(participant.id),
      roomId: drift.Value(participant.roomId),
      userId: drift.Value(participant.userId),
      cookingSessionId: drift.Value(participant.cookingSessionId),
      joinedAt: drift.Value(participant.joinedAt),
      leftAt: drift.Value(participant.leftAt),
      isActive: drift.Value(participant.isActive),
      recipeName: drift.Value(participant.recipeName),
      currentStep: drift.Value(participant.currentStep),
      energyLevel: drift.Value(participant.energyLevel),
      lastActivityAt: drift.Value(participant.lastActivityAt),
      messageCount: drift.Value(participant.messageCount),
      createdAt: drift.Value(participant.createdAt),
      updatedAt: drift.Value(participant.updatedAt),
      syncedToServer: const drift.Value(true),
    );
  }
}
