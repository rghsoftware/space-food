/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/meal_reminder.dart';
import '../models/meal_log.dart';
import '../models/eating_timeline.dart';

part 'meal_reminder_api.g.dart';

@RestApi()
abstract class MealReminderApi {
  factory MealReminderApi(Dio dio, {String baseUrl}) = _MealReminderApi;

  // Meal Reminder endpoints
  @POST('/meal-reminders')
  Future<MealReminder> createReminder(@Body() CreateMealReminderRequest request);

  @GET('/meal-reminders')
  Future<List<MealReminder>> getReminders();

  @GET('/meal-reminders/{id}')
  Future<MealReminder> getReminder(@Path('id') String id);

  @PUT('/meal-reminders/{id}')
  Future<MealReminder> updateReminder(
    @Path('id') String id,
    @Body() UpdateMealReminderRequest request,
  );

  @DELETE('/meal-reminders/{id}')
  Future<void> deleteReminder(@Path('id') String id);

  // Meal Log endpoints
  @POST('/meal-logs')
  Future<LogMealResponse> logMeal(@Body() LogMealRequest request);

  @GET('/meal-logs/timeline')
  Future<TimelineResponse> getTimeline(
    @Query('start_date') String startDate,
    @Query('end_date') String endDate,
  );

  // Timeline Settings endpoints
  @GET('/eating-timeline-settings')
  Future<EatingTimelineSettings> getTimelineSettings();

  @PUT('/eating-timeline-settings')
  Future<EatingTimelineSettings> updateTimelineSettings(
    @Body() UpdateTimelineSettingsRequest request,
  );
}
