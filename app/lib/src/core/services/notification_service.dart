/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = initialized ?? false;

    // Request permissions on iOS
    await _requestPermissions();
  }

  /// Request notification permissions (mainly for iOS)
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _notifications
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Handle notification tap (navigate to kitchen mode, etc.)
    print('Notification tapped: ${response.payload}');
  }

  /// Show notification for timer completion
  Future<void> showTimerComplete({
    required String timerId,
    required String timerLabel,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'kitchen_timers',
      'Kitchen Timers',
      channelDescription: 'Notifications for kitchen timer completions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      timerId.hashCode,
      'Timer Complete',
      timerLabel,
      details,
      payload: 'timer:$timerId',
    );
  }

  /// Show notification for timer warning (expiring soon)
  Future<void> showTimerWarning({
    required String timerId,
    required String timerLabel,
    required int remainingSeconds,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'kitchen_timers',
      'Kitchen Timers',
      channelDescription: 'Notifications for kitchen timer completions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      timerId.hashCode,
      'Timer Expiring Soon',
      '$timerLabel - $remainingSeconds seconds remaining',
      details,
      payload: 'timer:$timerId',
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String timerId) async {
    await _notifications.cancel(timerId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
