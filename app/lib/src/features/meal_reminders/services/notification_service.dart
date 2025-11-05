/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../data/models/meal_reminder.dart';

/// Service for managing meal reminder notifications
class MealReminderNotificationService {
  static final MealReminderNotificationService _instance =
      MealReminderNotificationService._internal();

  factory MealReminderNotificationService() => _instance;

  MealReminderNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return result ?? androidResult ?? false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();

    // Check Android
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }

    // iOS doesn't have a direct check, assume true after permission request
    return true;
  }

  /// Schedule notifications for a meal reminder
  Future<void> scheduleMealReminder(MealReminder reminder) async {
    if (!_initialized) await initialize();
    if (!reminder.enabled) return;

    // Cancel existing notifications for this reminder
    await cancelMealReminder(reminder.id);

    // Schedule for each day of the week
    for (final dayOfWeek in reminder.daysOfWeek) {
      // Schedule main notification
      await _scheduleNotificationForDay(
        reminderId: reminder.id,
        dayOfWeek: dayOfWeek,
        time: reminder.scheduledTime,
        title: 'Meal Time: ${reminder.name}',
        body: 'Time for ${reminder.name}!',
        isPreAlert: false,
      );

      // Schedule pre-alert if configured
      if (reminder.preAlertMinutes > 0) {
        final preAlertTime = _subtractMinutes(
          reminder.scheduledTime,
          reminder.preAlertMinutes,
        );

        await _scheduleNotificationForDay(
          reminderId: reminder.id,
          dayOfWeek: dayOfWeek,
          time: preAlertTime,
          title: 'Upcoming: ${reminder.name}',
          body: '${reminder.name} in ${reminder.preAlertMinutes} minutes',
          isPreAlert: true,
        );
      }
    }
  }

  /// Cancel all notifications for a meal reminder
  Future<void> cancelMealReminder(String reminderId) async {
    if (!_initialized) await initialize();

    // Cancel notifications for all days
    for (int day = 0; day < 7; day++) {
      final mainId = _getNotificationId(reminderId, day, false);
      final preAlertId = _getNotificationId(reminderId, day, true);

      await _notifications.cancel(mainId);
      await _notifications.cancel(preAlertId);
    }
  }

  /// Cancel all meal reminder notifications
  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Schedule a notification for a specific day and time
  Future<void> _scheduleNotificationForDay({
    required String reminderId,
    required int dayOfWeek, // 0 = Sunday, 6 = Saturday
    required String time, // "HH:MM:SS"
    required String title,
    required String body,
    required bool isPreAlert,
  }) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Get next occurrence of this day and time
    final scheduledDate = _getNextDateForDayAndTime(dayOfWeek, hour, minute);

    // Generate unique notification ID
    final notificationId = _getNotificationId(reminderId, dayOfWeek, isPreAlert);

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'meal_reminders',
      'Meal Reminders',
      channelDescription: 'Notifications for meal times',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          'log_meal',
          'Log Meal',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'meal_reminder',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification (weekly recurring)
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '$reminderId|$isPreAlert',
    );
  }

  /// Get next occurrence of a specific day and time
  tz.TZDateTime _getNextDateForDayAndTime(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust to the target day of week
    while (scheduledDate.weekday % 7 != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the time has passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Generate unique notification ID
  int _getNotificationId(String reminderId, int dayOfWeek, bool isPreAlert) {
    // Use hash code to generate numeric ID
    final reminderHash = reminderId.hashCode % 100000;
    final dayPart = dayOfWeek * 10;
    final preAlertPart = isPreAlert ? 1 : 0;

    return reminderHash + dayPart + preAlertPart;
  }

  /// Subtract minutes from time string
  String _subtractMinutes(String timeStr, int minutes) {
    final parts = timeStr.split(':');
    var hour = int.parse(parts[0]);
    var minute = int.parse(parts[1]);
    final second = int.parse(parts[2]);

    minute -= minutes;

    while (minute < 0) {
      minute += 60;
      hour--;
    }

    if (hour < 0) {
      hour += 24;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'log_meal') {
      // Extract reminder ID from payload
      final payload = response.payload?.split('|');
      if (payload != null && payload.isNotEmpty) {
        final reminderId = payload[0];
        // TODO: Trigger quick log for this reminder
        // This will be handled by the app's navigation system
      }
    }
  }

  /// Show an immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'meal_reminders',
      'Meal Reminders',
      channelDescription: 'Notifications for meal times',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }
}
