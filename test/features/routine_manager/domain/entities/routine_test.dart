import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';

void main() {
  group('Routine Entity // Verifies INT-01, INT-04, INT-10', () {
    final alarm1 = const Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
    final alarm2 = const Alarm(id: '2', durationSeconds: 120, orderIndex: 1);
    final now = DateTime.now();

    test('should create a valid Routine with at least one alarm', () {
      final routine = Routine(
        id: '1',
        name: 'Morning Yoga',
        alarms: [alarm1],
        createdAt: now,
        updatedAt: now,
      );

      expect(routine.id, '1');
      expect(routine.name, 'Morning Yoga');
      expect(routine.alarms, hasLength(1));
    });

    test('should allow creating a Routine with empty alarms manually (draft mode)', () {
      final routine = Routine(
        id: '1',
        name: 'Empty Routine',
        alarms: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(routine.alarms, isEmpty);
    });

    test('should support value equality', () {
      final routine1 = Routine(
        id: '1',
        name: 'Yoga',
        alarms: [alarm1],
        createdAt: now,
        updatedAt: now,
      );
      final routine2 = Routine(
        id: '1',
        name: 'Yoga',
        alarms: [alarm1],
        createdAt: now,
        updatedAt: now,
      );
      
      expect(routine1, equals(routine2));
    });

    test('copyWith should return a new object with updated values', () {
      final routine = Routine(
        id: '1',
        name: 'Yoga',
        alarms: [alarm1],
        createdAt: now,
        updatedAt: now,
      );
      
      final updated = routine.copyWith(name: 'Power Yoga', alarms: [alarm1, alarm2]);
      
      expect(updated.name, 'Power Yoga');
      expect(updated.alarms, hasLength(2));
    });
  });
}
