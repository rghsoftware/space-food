// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/recipe_breakdown.dart';
import '../models/cooking_session.dart';
import '../models/cooking_timer.dart';
import '../models/body_doubling_room.dart';

part 'cooking_assistant_api_client.g.dart';

@RestApi()
abstract class CookingAssistantApiClient {
  factory CookingAssistantApiClient(Dio dio, {String baseUrl}) =
      _CookingAssistantApiClient;

  // Breakdown endpoints
  @POST('/cooking-assistant/breakdowns/generate')
  Future<RecipeBreakdown> generateBreakdown(
    @Body() GenerateBreakdownRequest request,
  );

  @GET('/cooking-assistant/breakdowns/{recipeId}')
  Future<RecipeBreakdown> getBreakdown(
    @Path('recipeId') String recipeId, {
    @Query('granularity') int? granularity,
    @Query('energy_level') int? energyLevel,
  });

  // Cooking Session endpoints
  @POST('/cooking-assistant/sessions')
  Future<CookingSession> startCookingSession(
    @Body() StartCookingSessionRequest request,
  );

  @GET('/cooking-assistant/sessions/{sessionId}')
  Future<CookingSession> getCookingSession(
    @Path('sessionId') String sessionId,
  );

  @GET('/cooking-assistant/sessions')
  Future<List<CookingSession>> getUserSessions({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  @PUT('/cooking-assistant/sessions/{sessionId}/progress')
  Future<Map<String, dynamic>> updateProgress(
    @Path('sessionId') String sessionId,
    @Body() UpdateSessionProgressRequest request,
  );

  @POST('/cooking-assistant/sessions/{sessionId}/pause')
  Future<Map<String, dynamic>> pauseSession(
    @Path('sessionId') String sessionId,
  );

  @POST('/cooking-assistant/sessions/{sessionId}/resume')
  Future<Map<String, dynamic>> resumeSession(
    @Path('sessionId') String sessionId,
  );

  @POST('/cooking-assistant/sessions/{sessionId}/complete')
  Future<Map<String, dynamic>> completeSession(
    @Path('sessionId') String sessionId,
  );

  @POST('/cooking-assistant/sessions/{sessionId}/abandon')
  Future<Map<String, dynamic>> abandonSession(
    @Path('sessionId') String sessionId,
  );

  @POST('/cooking-assistant/sessions/{sessionId}/steps/complete')
  Future<Map<String, dynamic>> completeStep(
    @Path('sessionId') String sessionId,
    @Body() CompleteStepRequest request,
  );

  // Timer endpoints
  @POST('/cooking-assistant/sessions/{sessionId}/timers')
  Future<CookingTimer> createTimer(
    @Path('sessionId') String sessionId,
    @Body() CreateTimerRequest request,
  );

  @GET('/cooking-assistant/sessions/{sessionId}/timers')
  Future<List<CookingTimer>> getSessionTimers(
    @Path('sessionId') String sessionId,
  );

  @PUT('/cooking-assistant/timers/{timerId}/pause')
  Future<Map<String, dynamic>> pauseTimer(
    @Path('timerId') String timerId,
  );

  @PUT('/cooking-assistant/timers/{timerId}/resume')
  Future<Map<String, dynamic>> resumeTimer(
    @Path('timerId') String timerId,
  );

  @PUT('/cooking-assistant/timers/{timerId}/complete')
  Future<Map<String, dynamic>> completeTimer(
    @Path('timerId') String timerId,
  );

  @PUT('/cooking-assistant/timers/{timerId}/cancel')
  Future<Map<String, dynamic>> cancelTimer(
    @Path('timerId') String timerId,
  );

  // Body Doubling Room endpoints
  @POST('/cooking-assistant/rooms')
  Future<BodyDoublingRoom> createRoom(
    @Body() CreateBodyDoublingRoomRequest request,
  );

  @POST('/cooking-assistant/rooms/join')
  Future<BodyDoublingRoom> joinRoom(
    @Body() JoinBodyDoublingRoomRequest request,
  );

  @POST('/cooking-assistant/rooms/{roomId}/leave')
  Future<Map<String, dynamic>> leaveRoom(
    @Path('roomId') String roomId,
  );

  @GET('/cooking-assistant/rooms/{roomId}')
  Future<BodyDoublingRoom> getRoom(
    @Path('roomId') String roomId,
  );

  @GET('/cooking-assistant/rooms/{roomId}/participants')
  Future<List<BodyDoublingParticipant>> getRoomParticipants(
    @Path('roomId') String roomId,
  );

  @GET('/cooking-assistant/rooms/public')
  Future<List<BodyDoublingRoom>> getPublicRooms({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  @PUT('/cooking-assistant/rooms/{roomId}/activity')
  Future<Map<String, dynamic>> updateParticipantActivity(
    @Path('roomId') String roomId,
    @Body() UpdateParticipantActivityRequest request,
  );
}
