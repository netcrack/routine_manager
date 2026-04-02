import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/domain/services/notification_strings.dart';

void main() {
  group('NotificationStrings', () {
    test('routineTitle should return formatted string', () {
      expect(NotificationStrings.routineTitle('Yoga'), 'Routine: Yoga');
    });

    test('alarmBody should return "Alarm n is complete!" for non-final alarms', () {
      expect(NotificationStrings.alarmBody(0, 3), 'Alarm 1 is complete!');
      expect(NotificationStrings.alarmBody(1, 3), 'Alarm 2 is complete!');
    });

    test('alarmBody should return "Final alarm is complete!" for the last alarm', () {
      expect(NotificationStrings.alarmBody(2, 3), 'Final alarm is complete!');
      expect(NotificationStrings.alarmBody(0, 1), 'Final alarm is complete!');
    });
  });
}
