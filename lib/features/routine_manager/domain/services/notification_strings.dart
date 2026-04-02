/// Notification Strings Utility - Centralized management of user-facing notification text.
/// // Fulfills INT-07, INT-08
class NotificationStrings {
  /// Standardized title for all routine-related notifications
  static String routineTitle(String routineName) => "Routine: $routineName";

  /// Standardized body for alarm notifications.
  /// Triggered after an alarm's duration reaches zero.
  static String alarmBody(int index, int totalAlarms) {
    final number = index + 1;
    if (index >= totalAlarms - 1) {
      return "Final alarm is complete!";
    }
    return "Alarm $number is complete!";
  }
}
