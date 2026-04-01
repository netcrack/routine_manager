import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';

import 'package:routine_manager/features/routine_manager/domain/services/notification_service.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/next_alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/start_session.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/stop_session.dart';

class MockNotificationService extends Mock implements NotificationService {}


void main() {
  late MockNotificationService mockNotification;

  late StartSessionUseCase startSession;
  late StopSessionUseCase stopSession;
  late NextAlarmUseCase nextAlarm;

  final routine = Routine(
    id: '1',
    name: 'Yoga',
    alarms: [
      const Alarm(id: 'a1', durationSeconds: 60, orderIndex: 0),
      const Alarm(id: 'a2', durationSeconds: 120, orderIndex: 1),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockNotification = MockNotificationService();
    startSession = StartSessionUseCase(notificationService: mockNotification);
    stopSession = StopSessionUseCase(
      notificationService: mockNotification,
    );
    nextAlarm = NextAlarmUseCase(
      notificationService: mockNotification,
    );
  });

  group('Session State Machine // Verifies INT-03, INT-05, INT-09, INT-11', () {
    test('StartSession should initialize a running session when idle and permitted', () async {
      when(() => mockNotification.checkPermissions()).thenAnswer((_) async => true);
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async => {});

      final result = await startSession.execute(
        routine: routine,
        currentSession: const ActiveSession(),
      );

      expect(result.status, SessionStatus.running);
      expect(result.routineId, routine.id);
      expect(result.activeAlarmIndex, 0);
    });

    test('StartSession should throw if another session is active (INT-09)', () async {
      const activeSession = ActiveSession(status: SessionStatus.running);
      
      expect(
        () => startSession.execute(routine: routine, currentSession: activeSession),
        throwsA(isA<StateError>()),
      );
    });

    test('StopSession should reset session and clear alerts (INT-05)', () async {
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      final result = await stopSession.execute();

      expect(result.status, SessionStatus.inactive);
      verify(() => mockNotification.cancelAll()).called(1);
    });

    test('NextAlarm should advance to next alarm and stop ringing (INT-03)', () async {
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async => {});
      
      final currentSession = ActiveSession(
        routineId: routine.id,
        activeAlarmIndex: 0,
        status: SessionStatus.ringing,
      );

      final result = await nextAlarm.execute(
        routine: routine,
        currentSession: currentSession,
      );

      expect(result.activeAlarmIndex, 1);
      expect(result.status, SessionStatus.running);
    });

    test('NextAlarm should complete session if last alarm is finished (INT-11)', () async {
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      final currentSession = ActiveSession(
        routineId: routine.id,
        activeAlarmIndex: 1, // Last alarm
        status: SessionStatus.ringing,
      );

      final result = await nextAlarm.execute(
        routine: routine,
        currentSession: currentSession,
      );

      expect(result.status, SessionStatus.completed);
    });
  });
}
