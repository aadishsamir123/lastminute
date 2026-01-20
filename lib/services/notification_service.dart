import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/homework.dart' as hw;

/// Background notification handler - must be top-level function
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('🔔 Notification tapped in background: ${notificationResponse.id}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const int _studyNotificationId = 1001;
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      print('ℹ️ Notifications not supported on web');
      return;
    }

    if (_initialized) {
      print('ℹ️ Notification service already initialized');
      return;
    }

    try {
      print('🔔 Initializing notification service...');
      tz.initializeTimeZones();

      // Set local timezone
      tz.setLocalLocation(tz.getLocation('America/New_York'));
      print('✅ Timezone initialized: ${tz.local}');

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      print('✅ Notification plugin initialized: $initialized');

      // Request permissions
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final granted = await androidPlugin?.requestNotificationsPermission();
        print('🔔 Android notification permission granted: $granted');

        // Request exact alarm permission for scheduled notifications
        final exactAlarmGranted = await androidPlugin
            ?.requestExactAlarmsPermission();
        print('🔔 Android exact alarm permission granted: $exactAlarmGranted');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        print('🔔 iOS notification permission granted: $granted');
      }

      _initialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ ERROR initializing notification service: $e');
      print('📋 Stack trace: $stackTrace');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('👆 User tapped notification: ${response.id}');
  }

  Future<void> scheduleHomeworkReminder(hw.Homework homework) async {
    if (kIsWeb) return;

    try {
      print(
        '🔔 Scheduling ${homework.reminderTimes.length} reminder(s) for "${homework.title}"',
      );

      if (homework.reminderTimes.isEmpty) {
        print('ℹ️ No reminder times set for this homework');
        return;
      }

      int scheduled = 0;
      for (int i = 0; i < homework.reminderTimes.length; i++) {
        final reminderTime = homework.reminderTimes[i];
        if (reminderTime.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: homework.id.hashCode + i,
            title: 'Homework Reminder: ${homework.title}',
            body:
                homework.description ?? 'Due: ${_formatDate(homework.dueDate)}',
            scheduledDate: reminderTime,
          );
          scheduled++;
          print(
            '✅ Scheduled reminder #${i + 1} for ${_formatDate(reminderTime)}',
          );
        } else {
          print('⏭️ Skipping past reminder time: ${_formatDate(reminderTime)}');
        }
      }

      print(
        '✅ Successfully scheduled $scheduled out of ${homework.reminderTimes.length} reminders',
      );
    } catch (e, stackTrace) {
      print('❌ ERROR scheduling homework reminder: $e');
      print('📋 Stack trace: $stackTrace');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      print('📅 Scheduling notification ID $id for $scheduledDate');

      // Calculate the delay from now to the scheduled date
      final delay = scheduledDate.difference(DateTime.now());

      if (delay.isNegative) {
        print('⏭️ Scheduled time is in the past, skipping');
        return;
      }

      // Use simpler scheduling approach without timezone complications
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(delay),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'homework_reminders',
            'Homework Reminders',
            channelDescription: 'Notifications for homework deadlines',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Notification scheduled successfully (ID: $id)');
    } catch (e, stackTrace) {
      print('❌ ERROR scheduling notification (ID: $id): $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> cancelHomeworkReminders(String homeworkId) async {
    if (kIsWeb) return;

    // Cancel all notifications for this homework (up to 10 possible reminders)
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(homeworkId.hashCode + i);
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Quick notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Study session ongoing notification (Android)
  Future<void> showStudyOngoing({required Duration remaining}) async {
    if (kIsWeb) return;
    try {
      await _notifications.show(
        _studyNotificationId,
        'Focus Session',
        _formatRemaining(remaining),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_session',
            'Study Session',
            channelDescription: 'Ongoing focus session status',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            category: AndroidNotificationCategory.progress,
            showWhen: false,
          ),
        ),
      );
    } catch (e) {
      print('❌ ERROR showing study ongoing notification: $e');
    }
  }

  Future<void> updateStudyOngoing({required Duration remaining}) async {
    if (kIsWeb) return;
    try {
      await _notifications.show(
        _studyNotificationId,
        'Focus Session',
        _formatRemaining(remaining),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_session',
            'Study Session',
            channelDescription: 'Ongoing focus session status',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            category: AndroidNotificationCategory.progress,
            showWhen: false,
          ),
        ),
      );
    } catch (e) {
      print('❌ ERROR updating study ongoing notification: $e');
    }
  }

  Future<void> stopStudyOngoing() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancel(_studyNotificationId);
    } catch (e) {
      print('❌ ERROR stopping study ongoing notification: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final timeStr = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return 'Remaining: $timeStr';
  }

  /// Show a test notification (for debug mode)
  Future<void> showTestNotification() async {
    if (kIsWeb) return;

    try {
      print('🧪 Showing test notification...');

      // Show instantly
      await showInstantNotification(
        title: 'Test Notification 🧪',
        body: 'This is a test notification. Notifications are working!',
      );

      // Also schedule one for 5 seconds from now
      final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
      await _scheduleNotification(
        id: 9999,
        title: 'Delayed Test Notification 🔔',
        body: 'This notification was scheduled 5 seconds ago',
        scheduledDate: scheduledDate,
      );

      print('✅ Test notifications sent (instant + 5 second delay)');
    } catch (e, stackTrace) {
      print('❌ ERROR showing test notification: $e');
      print('📋 Stack trace: $stackTrace');
    }
  }
}
