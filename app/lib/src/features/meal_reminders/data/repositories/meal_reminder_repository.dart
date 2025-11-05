/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_exception.dart';
import '../api/meal_reminder_api.dart';
import '../local/meal_reminders_database.dart';
import '../models/meal_reminder.dart';
import '../models/meal_log.dart';
import '../models/eating_timeline.dart';

/// Repository implementing offline-first meal reminder functionality
class MealReminderRepository {
  final MealReminderApi _api;
  final MealRemindersDatabase _database;
  final String _userId;
  final _uuid = const Uuid();

  MealReminderRepository(
    this._api,
    this._database,
    this._userId,
  );

  // ==================== Meal Reminders ====================

  /// Get all reminders - tries API first, falls back to local
  Future<Either<ApiException, List<MealReminder>>> getReminders() async {
    try {
      // Try to fetch from API
      final reminders = await _api.getReminders();

      // Update local database
      for (final reminder in reminders) {
        await _saveReminderLocally(reminder, synced: true);
      }

      return Right(reminders);
    } on DioException catch (e) {
      // If offline or error, return local data
      final localReminders = await _database.getAllReminders(_userId);
      final models = localReminders.map(_reminderFromDb).toList();
      return Right(models);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Get single reminder
  Future<Either<ApiException, MealReminder>> getReminder(String id) async {
    try {
      final reminder = await _api.getReminder(id);
      await _saveReminderLocally(reminder, synced: true);
      return Right(reminder);
    } on DioException catch (e) {
      // Fall back to local
      final localReminder = await _database.getReminderById(id);
      if (localReminder != null) {
        return Right(_reminderFromDb(localReminder));
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Create reminder - saves locally first, syncs when online
  Future<Either<ApiException, MealReminder>> createReminder(
    CreateMealReminderRequest request,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Create local reminder immediately
    final localReminder = MealRemindersCompanion(
      id: drift.Value(id),
      userId: drift.Value(_userId),
      name: drift.Value(request.name),
      scheduledTime: drift.Value(request.scheduledTime),
      preAlertMinutes: drift.Value(request.preAlertMinutes),
      enabled: drift.Value(request.enabled),
      daysOfWeek: drift.Value(jsonEncode(request.daysOfWeek)),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.insertReminder(localReminder);

    // Try to sync with server
    try {
      final serverReminder = await _api.createReminder(request);
      // Update local with server version
      await _saveReminderLocally(serverReminder, synced: true);
      return Right(serverReminder);
    } on DioException {
      // Return local version if offline
      return Right(_reminderFromCompanion(localReminder, id));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Update reminder
  Future<Either<ApiException, MealReminder>> updateReminder(
    String id,
    UpdateMealReminderRequest request,
  ) async {
    final now = DateTime.now();

    // Update locally first
    final localUpdate = MealRemindersCompanion(
      id: drift.Value(id),
      userId: drift.Value(_userId),
      name: drift.Value(request.name),
      scheduledTime: drift.Value(request.scheduledTime),
      preAlertMinutes: drift.Value(request.preAlertMinutes),
      enabled: drift.Value(request.enabled),
      daysOfWeek: drift.Value(jsonEncode(request.daysOfWeek)),
      updatedAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.updateReminder(localUpdate);

    // Try to sync with server
    try {
      final serverReminder = await _api.updateReminder(id, request);
      await _saveReminderLocally(serverReminder, synced: true);
      return Right(serverReminder);
    } on DioException {
      // Return local version if offline
      final localReminder = await _database.getReminderById(id);
      if (localReminder != null) {
        return Right(_reminderFromDb(localReminder));
      }
      return const Left(ApiException.unknown('Reminder not found locally'));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Delete reminder
  Future<Either<ApiException, void>> deleteReminder(String id) async {
    try {
      await _api.deleteReminder(id);
      await _database.deleteReminder(id);
      return const Right(null);
    } on DioException catch (e) {
      // Delete locally even if offline
      await _database.deleteReminder(id);
      return const Right(null);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Meal Logs ====================

  /// Log a meal - saves locally first, syncs when online
  Future<Either<ApiException, LogMealResponse>> logMeal(
    LogMealRequest request,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final loggedAt = request.loggedAt ?? now;

    // Save locally first
    final localLog = MealLogsCompanion(
      id: drift.Value(id),
      userId: drift.Value(_userId),
      reminderId: drift.Value(request.reminderId),
      loggedAt: drift.Value(loggedAt),
      scheduledFor: drift.Value(request.loggedAt),
      notes: drift.Value(request.notes),
      energyLevel: drift.Value(request.energyLevel),
      createdAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.insertMealLog(localLog);

    // Try to sync with server
    try {
      final response = await _api.logMeal(request);
      await _database.markMealLogSynced(response.id);
      return Right(response);
    } on DioException {
      // Return local version if offline
      return Right(LogMealResponse(
        id: id,
        userId: _userId,
        reminderId: request.reminderId,
        loggedAt: loggedAt,
        scheduledFor: request.loggedAt,
        notes: request.notes,
        energyLevel: request.energyLevel,
        createdAt: now,
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Get eating timeline - tries API first, falls back to local
  Future<Either<ApiException, TimelineResponse>> getTimeline(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _api.getTimeline(
        _formatDate(startDate),
        _formatDate(endDate),
      );
      return Right(response);
    } on DioException {
      // Fall back to local data
      final localLogs = await _database.getMealLogs(
        _userId,
        startDate,
        endDate,
      );
      final settings = await _getLocalSettings();

      // Build timeline from local logs
      final timeline = _buildLocalTimeline(localLogs, startDate, endDate);

      return Right(TimelineResponse(
        settings: settings,
        timeline: timeline,
      ));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Timeline Settings ====================

  /// Get timeline settings
  Future<Either<ApiException, EatingTimelineSettings>> getTimelineSettings() async {
    try {
      final settings = await _api.getTimelineSettings();
      await _saveSettingsLocally(settings, synced: true);
      return Right(settings);
    } on DioException {
      // Fall back to local
      final localSettings = await _getLocalSettings();
      return Right(localSettings);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  /// Update timeline settings
  Future<Either<ApiException, EatingTimelineSettings>> updateTimelineSettings(
    UpdateTimelineSettingsRequest request,
  ) async {
    final now = DateTime.now();

    // Update locally first
    final localSettings = EatingTimelineSettingsTableCompanion(
      userId: drift.Value(_userId),
      dailyMealGoal: drift.Value(request.dailyMealGoal),
      dailySnackGoal: drift.Value(request.dailySnackGoal),
      showStreak: drift.Value(request.showStreak),
      showMissedMeals: drift.Value(request.showMissedMeals),
      updatedAt: drift.Value(now),
      syncedToServer: const drift.Value(false),
    );

    await _database.insertOrUpdateTimelineSettings(localSettings);

    // Try to sync with server
    try {
      final settings = await _api.updateTimelineSettings(request);
      await _saveSettingsLocally(settings, synced: true);
      return Right(settings);
    } on DioException {
      // Return local version if offline
      final local = await _getLocalSettings();
      return Right(local);
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  // ==================== Sync Operations ====================

  /// Sync all unsynced data to server
  Future<void> syncToServer() async {
    try {
      // Sync unsynced reminders
      final unsyncedReminders = await _database.getUnsyncedReminders();
      for (final reminder in unsyncedReminders) {
        try {
          // Try to update on server
          await _api.updateReminder(
            reminder.id,
            UpdateMealReminderRequest(
              name: reminder.name,
              scheduledTime: reminder.scheduledTime,
              preAlertMinutes: reminder.preAlertMinutes,
              enabled: reminder.enabled,
              daysOfWeek: (jsonDecode(reminder.daysOfWeek) as List)
                  .cast<int>(),
            ),
          );
          await _database.markReminderSynced(reminder.id);
        } catch (_) {
          // Skip if sync fails for this item
        }
      }

      // Sync unsynced meal logs
      final unsyncedLogs = await _database.getUnsyncedMealLogs();
      for (final log in unsyncedLogs) {
        try {
          await _api.logMeal(LogMealRequest(
            reminderId: log.reminderId,
            loggedAt: log.loggedAt,
            notes: log.notes,
            energyLevel: log.energyLevel,
          ));
          await _database.markMealLogSynced(log.id);
        } catch (_) {
          // Skip if sync fails for this item
        }
      }
    } catch (_) {
      // Ignore sync errors
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _saveReminderLocally(
    MealReminder reminder, {
    required bool synced,
  }) async {
    final companion = MealRemindersCompanion(
      id: drift.Value(reminder.id),
      userId: drift.Value(reminder.userId),
      name: drift.Value(reminder.name),
      scheduledTime: drift.Value(reminder.scheduledTime),
      preAlertMinutes: drift.Value(reminder.preAlertMinutes),
      enabled: drift.Value(reminder.enabled),
      daysOfWeek: drift.Value(jsonEncode(reminder.daysOfWeek)),
      createdAt: drift.Value(reminder.createdAt),
      updatedAt: drift.Value(reminder.updatedAt),
      syncedToServer: drift.Value(synced),
    );
    await _database.insertReminder(companion);
  }

  Future<void> _saveSettingsLocally(
    EatingTimelineSettings settings, {
    required bool synced,
  }) async {
    final companion = EatingTimelineSettingsTableCompanion(
      userId: drift.Value(settings.userId),
      dailyMealGoal: drift.Value(settings.dailyMealGoal),
      dailySnackGoal: drift.Value(settings.dailySnackGoal),
      showStreak: drift.Value(settings.showStreak),
      showMissedMeals: drift.Value(settings.showMissedMeals),
      createdAt: drift.Value(settings.createdAt),
      updatedAt: drift.Value(settings.updatedAt),
      syncedToServer: drift.Value(synced),
    );
    await _database.insertOrUpdateTimelineSettings(companion);
  }

  Future<EatingTimelineSettings> _getLocalSettings() async {
    final local = await _database.getTimelineSettings(_userId);
    if (local != null) {
      return EatingTimelineSettings(
        userId: local.userId,
        dailyMealGoal: local.dailyMealGoal,
        dailySnackGoal: local.dailySnackGoal,
        showStreak: local.showStreak,
        showMissedMeals: local.showMissedMeals,
        createdAt: local.createdAt,
        updatedAt: local.updatedAt,
      );
    }

    // Return defaults if not found
    final now = DateTime.now();
    return EatingTimelineSettings(
      userId: _userId,
      dailyMealGoal: 3,
      dailySnackGoal: 2,
      showStreak: true,
      showMissedMeals: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  MealReminder _reminderFromDb(drift.TypedResult reminder) {
    final data = reminder as MealReminder;
    return MealReminder(
      id: data.id,
      userId: data.userId,
      name: data.name,
      scheduledTime: data.scheduledTime,
      preAlertMinutes: data.preAlertMinutes,
      enabled: data.enabled,
      daysOfWeek: (jsonDecode(data.daysOfWeek) as List).cast<int>(),
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  MealReminder _reminderFromCompanion(MealRemindersCompanion companion, String id) {
    return MealReminder(
      id: id,
      userId: companion.userId.value,
      name: companion.name.value,
      scheduledTime: companion.scheduledTime.value,
      preAlertMinutes: companion.preAlertMinutes.value,
      enabled: companion.enabled.value,
      daysOfWeek: (jsonDecode(companion.daysOfWeek.value) as List).cast<int>(),
      createdAt: companion.createdAt.value,
      updatedAt: companion.updatedAt.value,
    );
  }

  List<EatingTimeline> _buildLocalTimeline(
    List<MealLog> logs,
    DateTime startDate,
    DateTime endDate,
  ) {
    final Map<String, List<MealLog>> logsByDate = {};

    // Group logs by date
    for (final log in logs) {
      final dateKey = _formatDate(log.loggedAt);
      logsByDate.putIfAbsent(dateKey, () => []).add(log);
    }

    // Build timeline for each day in range
    final timeline = <EatingTimeline>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = _formatDate(currentDate);
      final dayLogs = logsByDate[dateKey] ?? [];

      // Count meals vs snacks (simplified - all counted as meals for now)
      final mealCount = dayLogs.length;
      final snackCount = 0;

      timeline.add(EatingTimeline(
        date: currentDate,
        mealCount: mealCount,
        snackCount: snackCount,
        totalCount: mealCount + snackCount,
        metGoals: mealCount >= 3, // Simplified goal check
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return timeline;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException.timeout('Request timeout');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException.network('No internet connection');
    }

    final statusCode = error.response?.statusCode;
    final message =
        error.response?.data['error'] ?? error.message ?? 'Unknown error';

    if (statusCode != null) {
      return ApiException.fromStatusCode(statusCode, message);
    }

    return ApiException.unknown(message);
  }
}
