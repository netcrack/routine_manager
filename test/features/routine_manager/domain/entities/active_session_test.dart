import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';

void main() {
  group('ActiveSession', () {
    test('initial factory sets startTime and status running', () {
      final session = ActiveSession.initial('routine-123');
      
      expect(session.routineId, 'routine-123');
      expect(session.status, SessionStatus.running);
      expect(session.startTime, isNotNull);
      expect(session.activeAlarmIndex, 0);
      expect(session.elapsedSeconds, 0);
    });

    test('copyWith updates startTime', () {
      final session = const ActiveSession(routineId: '1');
      final newStartTime = DateTime(2023, 1, 1);
      
      final updated = session.copyWith(startTime: newStartTime);
      
      expect(updated.startTime, newStartTime);
    });

    test('equality includes startTime', () {
      final date = DateTime(2023, 1, 1);
      final s1 = ActiveSession(routineId: '1', startTime: date);
      final s2 = ActiveSession(routineId: '1', startTime: date);
      final s3 = ActiveSession(routineId: '1', startTime: DateTime.now());
      
      expect(s1, s2);
      expect(s1, isNot(s3));
    });
  });
}
