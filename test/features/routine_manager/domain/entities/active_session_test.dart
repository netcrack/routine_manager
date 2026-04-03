import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';

void main() {
  group('ActiveSession', () {
    test('initial factory sets sessionStartTime, anchorTime and status running', () {
      final session = ActiveSession.initial('routine-123');
      
      expect(session.routineId, 'routine-123');
      expect(session.status, SessionStatus.running);
      expect(session.sessionStartTime, isNotNull);
      expect(session.anchorTime, isNotNull);
      expect(session.activeAlarmIndex, 0);
      expect(session.elapsedSeconds, 0);
    });

    test('copyWith updates anchorTime', () {
      final session = const ActiveSession(routineId: '1');
      final newAnchorTime = DateTime(2023, 1, 1);
      
      final updated = session.copyWith(anchorTime: newAnchorTime);
      
      expect(updated.anchorTime, newAnchorTime);
    });

    test('equality includes sessionStartTime and anchorTime', () {
      final date = DateTime(2023, 1, 1);
      final s1 = ActiveSession(routineId: '1', sessionStartTime: date, anchorTime: date);
      final s2 = ActiveSession(routineId: '1', sessionStartTime: date, anchorTime: date);
      final s3 = ActiveSession(routineId: '1', sessionStartTime: date, anchorTime: DateTime.now());
      
      expect(s1, s2);
      expect(s1, isNot(s3));
    });
  });
}
