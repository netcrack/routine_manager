// Verifies INT-03, INT-05, INT-09, INT-11 (Standard 8.4)
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/domain_error.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/session_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/services/notification_service.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/next_alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/start_session.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/stop_session.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockNotificationService mockNotification;
  late MockSessionRepository mockSessionRepo;

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

  setUpAll(() {
    registerFallbackValue(const ActiveSession());
  });

  setUp(() {
    mockNotification = MockNotificationService();
    mockSessionRepo = MockSessionRepository();
    
    startSession = StartSessionUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
    );
    stopSession = StopSessionUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
    );
    nextAlarm = NextAlarmUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
    );
  });

  group('Session State Machine (Journey 2 Refactor)', () {
    test('StartSession should verify singleton lock and persist running state (Standard 4.2)', () async {
      // Setup: 1. Read (Standard 4.2)
      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => const ActiveSession()); // Inactive
      
      // Setup: 3. Validate permissions
      when(() => mockNotification.checkPermissions()).thenAnswer((_) async => true);
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async => {});

      // Setup: 6. Persist (Standard 4.2)
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => {});

      final result = await startSession.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.running);
      expect(result.success.routineId, routine.id);
      
      verify(() => mockSessionRepo.loadSession()).called(1);
      verify(() => mockSessionRepo.saveSession(any())).called(1);
    });

    test('StartSession should fail if another session is active (INT-09, Standard 5.1)', () async {
      // Read active state
      when(() => mockSessionRepo.loadSession()).thenAnswer(
        (_) async => const ActiveSession(status: SessionStatus.running)
      );
      
      final result = await startSession.execute(routine);

      expect(result.isFailure, true);
      expect(result.failure, DomainError.activeSessionExists);
      verifyNever(() => mockSessionRepo.saveSession(any()));
    });

    test('StopSession should clear persistence and return success (INT-05)', () async {
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async => {});

      final result = await stopSession.execute();

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.inactive);
      verify(() => mockNotification.cancelAll()).called(1);
      verify(() => mockSessionRepo.clearSession()).called(1);
    });

    test('NextAlarm should advance to next alarm and stop ringing (INT-03)', () async {
      final currentSession = ActiveSession(
        routineId: routine.id,
        activeAlarmIndex: 0,
        status: SessionStatus.ringing,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => currentSession);
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async => {});
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => {});
      
      final result = await nextAlarm.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.activeAlarmIndex, 1);
      expect(result.success.status, SessionStatus.running);
      verify(() => mockSessionRepo.saveSession(any())).called(1);
    });

    test('NextAlarm should complete session if last alarm is finished (INT-11)', () async {
      final currentSession = ActiveSession(
        routineId: routine.id,
        activeAlarmIndex: 1, // Last alarm
        status: SessionStatus.ringing,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => currentSession);
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => {});

      final result = await nextAlarm.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.inactive);
    });
  });
}
