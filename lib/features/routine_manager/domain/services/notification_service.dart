/// Notification Service Interface - Absract contract for background alerts.
/// // Fulfills INT-07, INT-09
abstract class NotificationService {
  /// Check if the app has required notification permissions.
  Future<bool> checkPermissions();

  /// Request notification permissions.
  Future<bool> requestPermissions();

  /// Schedule a notification for a specific time and content.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });

  /// Stream emitting notification payloads when a user interacts with a notification.
  Stream<String?> get onNotificationClick;

  /// Cancel all pending notifications.
  Future<void> cancelAll();
}
