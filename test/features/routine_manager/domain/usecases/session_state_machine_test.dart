// Verifies INT-03, INT-05, INT-09, INT-11 (Standard 8.4)
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/domain_error.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/core/result.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/session_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/history_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine_run.dart';
import 'package:routine_manager/features/routine_manager/domain/services/notification_service.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/next_alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/start_session.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/stop_session.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockSessionRepository extends Mock implements SessionRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockNotificationService mockNotification;
  late MockSessionRepository mockSessionRepo;
  late MockHistoryRepository mockHistoryRepo;

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
    registerFallbackValue(RoutineRun(
      id: '1', 
      routineId: '1', 
      routineName: 'Test', 
      startTime: DateTime.now(),
      endTime: DateTime.now(), 
      status: RunStatus.completed,
    ));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockNotification = MockNotificationService();
    mockSessionRepo = MockSessionRepository();
    mockHistoryRepo = MockHistoryRepository();
    
    startSession = StartSessionUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
    );
    stopSession = StopSessionUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
      historyRepository: mockHistoryRepo,
    );
    nextAlarm = NextAlarmUseCase(
      notificationService: mockNotification,
      sessionRepository: mockSessionRepo,
      historyRepository: mockHistoryRepo,
    );
  });

  group('Session State Machine (Journey 2 Refactor)', () {
    test('StartSession should verify singleton lock and persist running state (Standard 4.2)', () async {
      // Setup: 1. Read (Standard 4.2)
      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => const Result.success(ActiveSession())); // Inactive
      
      // Setup: 3. Validate permissions
      when(() => mockNotification.checkPermissions()).thenAnswer((_) async => true);
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});

      // Setup: 6. Persist (Standard 4.2)
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => const Result.success(null));

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
        (_) async => const Result.success(ActiveSession(status: SessionStatus.running))
      );
      
      final result = await startSession.execute(routine);

      expect(result.isFailure, true);
      expect(result.failure, DomainError.activeSessionExists);
      verifyNever(() => mockSessionRepo.saveSession(any()));
    });

    test('StartSession should fail if routine has no alarms (Journey 3 Invariant)', () async {
      final emptyRoutine = Routine(
        id: 'empty',
        name: 'Empty',
        alarms: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => const Result.success(ActiveSession()));

      final result = await startSession.execute(emptyRoutine);

      expect(result.isFailure, true);
      expect(result.failure, DomainError.invalidRoutine);
      verifyNever(() => mockSessionRepo.saveSession(any()));
    });

    test('StartSession should propagate storage failure (Journey 3 Resilience)', () async {
      when(() => mockSessionRepo.loadSession()).thenAnswer(
        (_) async => const Result.failure(DomainError.storageFailure)
      );

      final result = await startSession.execute(routine);

      expect(result.isFailure, true);
      expect(result.failure, DomainError.storageFailure);
    });

    test('StopSession should record history and clear persistence (INT-05, INT-15)', () async {
      final currentSession = ActiveSession(
        routineId: routine.id,
        status: SessionStatus.running,
        sessionStartTime: DateTime.now(),
        anchorTime: DateTime.now(),
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(currentSession));
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockHistoryRepo.saveRun(any())).thenAnswer((_) async => const Result.success(null));
      when(() => mockHistoryRepo.pruneHistory(any())).thenAnswer((_) async => const Result.success(null));
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async => const Result.success(null));

      final result = await stopSession.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.inactive);
      verify(() => mockNotification.cancelAll()).called(1);
      verify(() => mockHistoryRepo.saveRun(any())).called(1);
      verify(() => mockHistoryRepo.pruneHistory(any())).called(1);
      verify(() => mockSessionRepo.clearSession()).called(1);
    });

    test('NextAlarm should advance to next alarm and stop ringing (INT-03)', () async {
      final currentSession = ActiveSession(
        routineId: routine.id,
        activeAlarmIndex: 0,
        status: SessionStatus.ringing,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(currentSession));
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockNotification.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => const Result.success(null));
      
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
        sessionStartTime: DateTime.now(),
        anchorTime: DateTime.now(),
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(currentSession));
      when(() => mockNotification.cancelAll()).thenAnswer((_) async => {});
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => const Result.success(null));
      when(() => mockHistoryRepo.saveRun(any())).thenAnswer((_) async => const Result.success(null));
      when(() => mockHistoryRepo.pruneHistory(any())).thenAnswer((_) async => const Result.success(null));

      final result = await nextAlarm.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.inactive);
      verify(() => mockHistoryRepo.saveRun(any())).called(1);
      verify(() => mockHistoryRepo.pruneHistory(any())).called(1);
    });
  });
}
