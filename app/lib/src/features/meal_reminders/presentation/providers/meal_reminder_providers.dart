/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/api/meal_reminder_api.dart';
import '../../data/local/meal_reminders_database.dart';
import '../../data/repositories/meal_reminder_repository.dart';
import '../../data/models/meal_reminder.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/eating_timeline.dart';
import '../../services/notification_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/dio_provider.dart';

part 'meal_reminder_providers.g.dart';

// ==================== Infrastructure Providers ====================

/// Provides the Drift database instance
@riverpod
MealRemindersDatabase mealRemindersDatabase(MealRemindersDatabaseRef ref) {
  return MealRemindersDatabase();
}

/// Provides the meal reminder API client
@riverpod
MealReminderApi mealReminderApi(MealReminderApiRef ref) {
  final dio = ref.watch(dioProvider);
  return MealReminderApi(dio, baseUrl: '${dio.options.baseUrl}/api/v1');
}

/// Provides the notification service
@riverpod
MealReminderNotificationService notificationService(NotificationServiceRef ref) {
  return MealReminderNotificationService();
}

/// Provides the meal reminder repository
@riverpod
MealReminderRepository mealReminderRepository(MealReminderRepositoryRef ref) {
  final api = ref.watch(mealReminderApiProvider);
  final database = ref.watch(mealRemindersDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);

  return MealReminderRepository(api, database, userId);
}

// ==================== State Providers ====================

/// Provides the list of meal reminders
@riverpod
class MealReminders extends _$MealReminders {
  @override
  Future<List<MealReminder>> build() async {
    final repository = ref.watch(mealReminderRepositoryProvider);
    final result = await repository.getReminders();

    return result.fold(
      (error) => throw error,
      (reminders) => reminders,
    );
  }

  /// Create a new meal reminder
  Future<void> createReminder(CreateMealReminderRequest request) async {
    state = const AsyncValue.loading();

    final repository = ref.read(mealReminderRepositoryProvider);
    final result = await repository.createReminder(request);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (error) => throw error,
        (reminder) async {
          // Schedule notifications
          await _scheduleNotification(reminder);

          // Refresh list
          final refreshResult = await repository.getReminders();
          return refreshResult.fold(
            (error) => throw error,
            (reminders) => reminders,
          );
        },
      );
    });
  }

  /// Update an existing meal reminder
  Future<void> updateReminder(
    String id,
    UpdateMealReminderRequest request,
  ) async {
    final repository = ref.read(mealReminderRepositoryProvider);
    final result = await repository.updateReminder(id, request);

    await result.fold(
      (error) => throw error,
      (reminder) async {
        // Reschedule notifications
        await _scheduleNotification(reminder);

        // Refresh list
        ref.invalidateSelf();
      },
    );
  }

  /// Delete a meal reminder
  Future<void> deleteReminder(String id) async {
    final repository = ref.read(mealReminderRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // Cancel notifications
    await notificationService.cancelMealReminder(id);

    // Delete from backend/local
    final result = await repository.deleteReminder(id);

    await result.fold(
      (error) => throw error,
      (_) async {
        // Refresh list
        ref.invalidateSelf();
      },
    );
  }

  /// Toggle reminder enabled/disabled
  Future<void> toggleReminder(String id, bool enabled) async {
    final currentReminders = state.value ?? [];
    final reminder = currentReminders.firstWhere((r) => r.id == id);

    final request = UpdateMealReminderRequest(
      name: reminder.name,
      scheduledTime: reminder.scheduledTime,
      preAlertMinutes: reminder.preAlertMinutes,
      enabled: enabled,
      daysOfWeek: reminder.daysOfWeek,
    );

    await updateReminder(id, request);
  }

  Future<void> _scheduleNotification(MealReminder reminder) async {
    final notificationService = ref.read(notificationServiceProvider);

    if (reminder.enabled) {
      await notificationService.scheduleMealReminder(reminder);
    } else {
      await notificationService.cancelMealReminder(reminder.id);
    }
  }
}

/// Provides a single meal reminder by ID
@riverpod
Future<MealReminder> mealReminder(MealReminderRef ref, String id) async {
  final repository = ref.watch(mealReminderRepositoryProvider);
  final result = await repository.getReminder(id);

  return result.fold(
    (error) => throw error,
    (reminder) => reminder,
  );
}

/// Provides the eating timeline
@riverpod
class EatingTimelineData extends _$EatingTimelineData {
  @override
  Future<TimelineResponse> build(DateTime startDate, DateTime endDate) async {
    final repository = ref.watch(mealReminderRepositoryProvider);
    final result = await repository.getTimeline(startDate, endDate);

    return result.fold(
      (error) => throw error,
      (timeline) => timeline,
    );
  }

  /// Refresh timeline data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provides timeline settings
@riverpod
class TimelineSettingsData extends _$TimelineSettingsData {
  @override
  Future<EatingTimelineSettings> build() async {
    final repository = ref.watch(mealReminderRepositoryProvider);
    final result = await repository.getTimelineSettings();

    return result.fold(
      (error) => throw error,
      (settings) => settings,
    );
  }

  /// Update timeline settings
  Future<void> updateSettings(UpdateTimelineSettingsRequest request) async {
    state = const AsyncValue.loading();

    final repository = ref.read(mealReminderRepositoryProvider);
    final result = await repository.updateTimelineSettings(request);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (error) => throw error,
        (settings) => settings,
      );
    });
  }
}

/// Provides meal logging functionality
@riverpod
class MealLogger extends _$MealLogger {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Log a meal
  Future<LogMealResponse> logMeal(LogMealRequest request) async {
    final repository = ref.read(mealReminderRepositoryProvider);
    final result = await repository.logMeal(request);

    // Invalidate timeline to refresh
    ref.invalidate(eatingTimelineDataProvider);

    return result.fold(
      (error) => throw error,
      (response) => response,
    );
  }

  /// Quick log a meal (one-tap, minimal data)
  Future<LogMealResponse> quickLog({String? reminderId}) async {
    return await logMeal(LogMealRequest(
      reminderId: reminderId,
      loggedAt: DateTime.now(),
    ));
  }

  /// Log a meal with energy level
  Future<LogMealResponse> logWithEnergy({
    String? reminderId,
    required int energyLevel,
    String? notes,
  }) async {
    return await logMeal(LogMealRequest(
      reminderId: reminderId,
      loggedAt: DateTime.now(),
      energyLevel: energyLevel,
      notes: notes,
    ));
  }
}

/// Provides notification permission status
@riverpod
class NotificationPermissionStatus extends _$NotificationPermissionStatus {
  @override
  Future<bool> build() async {
    final notificationService = ref.watch(notificationServiceProvider);
    await notificationService.initialize();
    return await notificationService.areNotificationsEnabled();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final notificationService = ref.read(notificationServiceProvider);
    final granted = await notificationService.requestPermissions();

    state = AsyncValue.data(granted);
    return granted;
  }

  /// Refresh permission status
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provides background sync status
@riverpod
class BackgroundSync extends _$BackgroundSync {
  @override
  FutureOr<void> build() {
    // Start periodic sync when provider is created
    _startPeriodicSync();
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    final repository = ref.read(mealReminderRepositoryProvider);
    await repository.syncToServer();

    // Refresh all data after sync
    ref.invalidate(mealRemindersProvider);
    ref.invalidate(eatingTimelineDataProvider);
    ref.invalidate(timelineSettingsDataProvider);
  }

  /// Start periodic background sync (every 15 minutes)
  void _startPeriodicSync() {
    // TODO: Implement periodic sync using WorkManager or similar
    // For now, just expose manual sync
  }
}

// ==================== Helper Providers ====================

/// Provides current user ID from auth provider
@riverpod
String currentUserId(CurrentUserIdRef ref) {
  // TODO: Get from actual auth provider
  // final user = ref.watch(currentUserProvider);
  // return user?.id ?? '';
  return 'current-user-id'; // Placeholder
}

/// Provides today's eating timeline
@riverpod
Future<EatingTimeline> todaysTimeline(TodaysTimelineRef ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final timelineData = await ref.watch(
    eatingTimelineDataProvider(startOfDay, endOfDay).future,
  );

  return timelineData.timeline.firstWhere(
    (t) => t.date.day == now.day &&
        t.date.month == now.month &&
        t.date.year == now.year,
    orElse: () => EatingTimeline(
      date: now,
      mealCount: 0,
      snackCount: 0,
      totalCount: 0,
      metGoals: false,
    ),
  );
}

/// Provides pending notification count (for debugging)
@riverpod
Future<int> pendingNotificationCount(PendingNotificationCountRef ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  final pending = await notificationService.getPendingNotifications();
  return pending.length;
}
