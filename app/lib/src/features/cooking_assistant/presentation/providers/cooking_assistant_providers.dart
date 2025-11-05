// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/cooking_assistant_database.dart';
import '../../data/remote/cooking_assistant_api_client.dart';
import '../../data/repositories/cooking_assistant_repository.dart';
import '../../data/models/recipe_breakdown.dart';
import '../../data/models/cooking_session.dart';
import '../../data/models/cooking_timer.dart';
import '../../data/models/body_doubling_room.dart';

part 'cooking_assistant_providers.g.dart';

// Database provider
@riverpod
CookingAssistantDatabase cookingAssistantDatabase(
    CookingAssistantDatabaseRef ref) {
  return CookingAssistantDatabase();
}

// API client provider
@riverpod
CookingAssistantApiClient cookingAssistantApiClient(
    CookingAssistantApiClientRef ref) {
  // TODO: Get Dio instance from shared provider
  throw UnimplementedError('Dio instance provider needed');
}

// Repository provider
@riverpod
CookingAssistantRepository cookingAssistantRepository(
    CookingAssistantRepositoryRef ref) {
  return CookingAssistantRepository(
    apiClient: ref.watch(cookingAssistantApiClientProvider),
    database: ref.watch(cookingAssistantDatabaseProvider),
  );
}

// Recipe Breakdown providers

@riverpod
Future<RecipeBreakdown> recipeBreakdown(
  RecipeBreakdownRef ref,
  String recipeId, {
  int granularity = 3,
  int? energyLevel,
}) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getBreakdown(
    recipeId,
    granularity: granularity,
    energyLevel: energyLevel,
  );
  return result.fold(
    (error) => throw Exception(error),
    (breakdown) => breakdown,
  );
}

@riverpod
class BreakdownGenerator extends _$BreakdownGenerator {
  @override
  FutureOr<RecipeBreakdown?> build() => null;

  Future<RecipeBreakdown> generateBreakdown({
    required String recipeId,
    required int granularityLevel,
    int? energyLevel,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = GenerateBreakdownRequest(
      recipeId: recipeId,
      granularityLevel: granularityLevel,
      energyLevel: energyLevel,
    );

    final result = await repository.generateBreakdown(request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (breakdown) {
        state = AsyncValue.data(breakdown);
        return breakdown;
      },
    );
  }
}

// Cooking Session providers

@riverpod
Future<CookingSession> cookingSession(
  CookingSessionRef ref,
  String sessionId,
) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getCookingSession(sessionId);
  return result.fold(
    (error) => throw Exception(error),
    (session) => session,
  );
}

@riverpod
Future<List<CookingSession>> userCookingSessions(
  UserCookingSessionsRef ref, {
  int limit = 20,
  int offset = 0,
}) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getUserSessions(
    limit: limit,
    offset: offset,
  );
  return result.fold(
    (error) => throw Exception(error),
    (sessions) => sessions,
  );
}

@riverpod
Future<CookingSession?> activeCookingSession(
    ActiveCookingSessionRef ref) async {
  final sessions = await ref.watch(userCookingSessionsProvider().future);
  return sessions.where((s) => s.status == 'active' || s.status == 'paused').firstOrNull;
}

@riverpod
class CookingSessionController extends _$CookingSessionController {
  @override
  FutureOr<CookingSession?> build() => null;

  Future<CookingSession> startSession({
    required String recipeId,
    String? breakdownId,
    int? energyLevel,
    String? joinRoomCode,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = StartCookingSessionRequest(
      recipeId: recipeId,
      breakdownId: breakdownId,
      energyLevel: energyLevel,
      joinRoomCode: joinRoomCode,
    );

    final result = await repository.startCookingSession(request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (session) {
        state = AsyncValue.data(session);
        ref.invalidate(userCookingSessionsProvider);
        ref.invalidate(activeCookingSessionProvider);
        return session;
      },
    );
  }

  Future<void> updateProgress({
    required String sessionId,
    required int currentStepIndex,
    String? notes,
  }) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = UpdateSessionProgressRequest(
      currentStepIndex: currentStepIndex,
      notes: notes,
    );

    final result = await repository.updateProgress(sessionId, request);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        ref.invalidate(cookingSessionProvider(sessionId));
        ref.invalidate(activeCookingSessionProvider);
      },
    );
  }

  Future<void> pauseSession(String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.pauseSession(sessionId);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        ref.invalidate(cookingSessionProvider(sessionId));
        ref.invalidate(activeCookingSessionProvider);
      },
    );
  }

  Future<void> resumeSession(String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.resumeSession(sessionId);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        ref.invalidate(cookingSessionProvider(sessionId));
        ref.invalidate(activeCookingSessionProvider);
      },
    );
  }

  Future<void> completeSession(String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.completeSession(sessionId);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        ref.invalidate(cookingSessionProvider(sessionId));
        ref.invalidate(userCookingSessionsProvider);
        ref.invalidate(activeCookingSessionProvider);
      },
    );
  }

  Future<void> abandonSession(String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.abandonSession(sessionId);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        ref.invalidate(cookingSessionProvider(sessionId));
        ref.invalidate(userCookingSessionsProvider);
        ref.invalidate(activeCookingSessionProvider);
      },
    );
  }

  Future<void> completeStep({
    required String sessionId,
    required int stepIndex,
    required String stepText,
    int? timeTakenSeconds,
    bool skipped = false,
    int? difficultyRating,
    String? notes,
  }) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = CompleteStepRequest(
      stepIndex: stepIndex,
      stepText: stepText,
      timeTakenSeconds: timeTakenSeconds,
      skipped: skipped,
      difficultyRating: difficultyRating,
      notes: notes,
    );

    final result = await repository.completeStep(sessionId, request);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(cookingSessionProvider(sessionId)),
    );
  }
}

// Timer providers

@riverpod
Future<List<CookingTimer>> sessionTimers(
  SessionTimersRef ref,
  String sessionId,
) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getSessionTimers(sessionId);
  return result.fold(
    (error) => throw Exception(error),
    (timers) => timers,
  );
}

@riverpod
class TimerController extends _$TimerController {
  @override
  FutureOr<CookingTimer?> build() => null;

  Future<CookingTimer> createTimer({
    required String sessionId,
    int? stepIndex,
    required String name,
    required int durationSeconds,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = CreateTimerRequest(
      stepIndex: stepIndex,
      name: name,
      durationSeconds: durationSeconds,
    );

    final result = await repository.createTimer(sessionId, request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (timer) {
        state = AsyncValue.data(timer);
        ref.invalidate(sessionTimersProvider(sessionId));
        return timer;
      },
    );
  }

  Future<void> pauseTimer(String timerId, String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.pauseTimer(timerId);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(sessionTimersProvider(sessionId)),
    );
  }

  Future<void> resumeTimer(String timerId, String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.resumeTimer(timerId);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(sessionTimersProvider(sessionId)),
    );
  }

  Future<void> completeTimer(String timerId, String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.completeTimer(timerId);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(sessionTimersProvider(sessionId)),
    );
  }

  Future<void> cancelTimer(String timerId, String sessionId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.cancelTimer(timerId);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(sessionTimersProvider(sessionId)),
    );
  }
}

// Body Doubling Room providers

@riverpod
Future<BodyDoublingRoom> bodyDoublingRoom(
  BodyDoublingRoomRef ref,
  String roomId,
) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getRoom(roomId);
  return result.fold(
    (error) => throw Exception(error),
    (room) => room,
  );
}

@riverpod
Future<List<BodyDoublingParticipant>> roomParticipants(
  RoomParticipantsRef ref,
  String roomId,
) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getRoomParticipants(roomId);
  return result.fold(
    (error) => throw Exception(error),
    (participants) => participants,
  );
}

@riverpod
Future<List<BodyDoublingRoom>> publicRooms(
  PublicRoomsRef ref, {
  int limit = 20,
  int offset = 0,
}) async {
  final repository = ref.watch(cookingAssistantRepositoryProvider);
  final result = await repository.getPublicRooms(
    limit: limit,
    offset: offset,
  );
  return result.fold(
    (error) => throw Exception(error),
    (rooms) => rooms,
  );
}

@riverpod
class BodyDoublingController extends _$BodyDoublingController {
  @override
  FutureOr<BodyDoublingRoom?> build() => null;

  Future<BodyDoublingRoom> createRoom({
    required String roomName,
    String? description,
    int maxParticipants = 10,
    bool isPublic = false,
    String? password,
    DateTime? scheduledStartTime,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = CreateBodyDoublingRoomRequest(
      roomName: roomName,
      description: description,
      maxParticipants: maxParticipants,
      isPublic: isPublic,
      password: password,
      scheduledStartTime: scheduledStartTime,
    );

    final result = await repository.createRoom(request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (room) {
        state = AsyncValue.data(room);
        ref.invalidate(publicRoomsProvider);
        return room;
      },
    );
  }

  Future<BodyDoublingRoom> joinRoom({
    required String roomCode,
    String? password,
    String? cookingSessionId,
    String? recipeName,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = JoinBodyDoublingRoomRequest(
      roomCode: roomCode,
      password: password,
      cookingSessionId: cookingSessionId,
      recipeName: recipeName,
    );

    final result = await repository.joinRoom(request);
    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        throw Exception(error);
      },
      (room) {
        state = AsyncValue.data(room);
        ref.invalidate(bodyDoublingRoomProvider(room.id));
        ref.invalidate(roomParticipantsProvider(room.id));
        return room;
      },
    );
  }

  Future<void> leaveRoom(String roomId) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final result = await repository.leaveRoom(roomId);
    result.fold(
      (error) => throw Exception(error),
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(bodyDoublingRoomProvider(roomId));
        ref.invalidate(roomParticipantsProvider(roomId));
        ref.invalidate(publicRoomsProvider);
      },
    );
  }

  Future<void> updateActivity({
    required String roomId,
    String? currentStep,
    int? energyLevel,
  }) async {
    final repository = ref.read(cookingAssistantRepositoryProvider);
    final request = UpdateParticipantActivityRequest(
      currentStep: currentStep,
      energyLevel: energyLevel,
    );

    final result = await repository.updateParticipantActivity(roomId, request);
    result.fold(
      (error) => throw Exception(error),
      (_) => ref.invalidate(roomParticipantsProvider(roomId)),
    );
  }
}

// Helper providers for UI state

@riverpod
String timeOfDay(TimeOfDayRef ref) {
  final now = DateTime.now();
  if (now.hour >= 5 && now.hour < 12) return 'morning';
  if (now.hour >= 12 && now.hour < 17) return 'afternoon';
  if (now.hour >= 17 && now.hour < 21) return 'evening';
  return 'night';
}
