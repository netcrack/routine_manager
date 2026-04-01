import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';

void main() {
  group('Alarm Entity // Verifies INT-02, INT-04', () {
    test('should create a valid Alarm', () {
      const alarm = Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
      expect(alarm.id, '1');
      expect(alarm.durationSeconds, 60);
      expect(alarm.orderIndex, 0);
    });

    test('should throw AssertionError when durationSeconds is 0', () {
      expect(
        () => Alarm(id: '1', durationSeconds: 0, orderIndex: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError when durationSeconds is negative', () {
      expect(
        () => Alarm(id: '1', durationSeconds: -10, orderIndex: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should support value equality', () {
      const alarm1 = Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
      const alarm2 = Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
      const alarm3 = Alarm(id: '2', durationSeconds: 60, orderIndex: 0);

      expect(alarm1, equals(alarm2));
      expect(alarm1, isNot(equals(alarm3)));
    });

    test('copyWith should return a new object with updated values', () {
      const alarm = Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
      final updated = alarm.copyWith(durationSeconds: 120);

      expect(updated.id, '1');
      expect(updated.durationSeconds, 120);
      expect(updated.orderIndex, 0);
    });
  });
}
