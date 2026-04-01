import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/routine_manager/domain/services/notification_service.dart';

/// Local Notification Service Implementation - Native integration for background alerts.
/// // Fulfills INT-07, INT-09
class LocalNotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationServiceImpl(this._plugin);

  /// Initialize the notification system.
  Future<void> init() async {
    // 1. Initialize Timezone data (Required for scheduling)
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));

    // 2. Plugin setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Note: DarwinInitializationSettings handles both iOS and macOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification touch here if needed
      },
    );
  }

  @override
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      // For iOS/macOS, if we can't definitively check without a separate package,
      // it's safer to return false so that `requestPermissions()` is explicitly called.
      // The native platform will simply return true without prompting if permissions
      // are already granted.
      return false;
    }
    return false;
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    } else if (Platform.isMacOS) {
      final macOsImplementation = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      return await macOsImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final androidScheduleMode = await _resolveAndroidScheduleMode();
    final notificationDetails = _getAlarmNotificationDetails();

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (Platform.isAndroid &&
          e.code == 'exact_alarms_not_permitted' &&
          androidScheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        return;
      }
      rethrow;
    }
  }

  /// Single Source of Truth for Routine Alarm Notifications.
  /// // Fulfills INT-07, INT-08 and approved "Single Sound Config"
  NotificationDetails _getAlarmNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_alarms_channel_v2',
        'Routine Alarms (High Priority)',
        channelDescription: 'Heads-up notifications for routine alarms',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        // Explicitly use the system default alarm ringtone URI
        sound: const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT (loops the sound)
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact =
        await androidImplementation?.canScheduleExactNotifications() ?? false;

    return canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
