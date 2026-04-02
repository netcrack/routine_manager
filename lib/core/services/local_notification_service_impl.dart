import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  final _onNotificationClickController = StreamController<String?>.broadcast();

  LocalNotificationServiceImpl(this._plugin);

  @override
  Stream<String?> get onNotificationClick => _onNotificationClickController.stream;

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
        _onNotificationClickController.add(details.payload);
      },
    );
  }

  @override
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      final notificationsEnabled = await androidPlugin?.areNotificationsEnabled() ?? false;
      final canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? true;
      
    return notificationsEnabled && canScheduleExact;
    }
    
    // Fallback for other platforms (iOS/macOS)
    return true; 
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      // For Android, we request standard notification permission.
      // Note: Exact alarm permission usually requires an Intent to settings on Android 13+.
      final granted = await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted;
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
    String? payload,
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
        payload: payload,
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
          payload: payload,
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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    // Check if the user has granted the SCHEDULE_EXACT_ALARM permission.
    // Note: We also have USE_EXACT_ALARM in the manifest now, which is auto-granted.
    final canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? false;

    // Use alarmClock for the most reliable system-level triggering
    return canScheduleExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
