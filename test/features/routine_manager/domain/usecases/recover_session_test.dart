// Verifies Standard 6.2 (Zombie Recovery)
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/result.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine_run.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/history_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/routine_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/session_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/recover_session.dart';

class MockSessionRepository extends Mock implements SessionRepository {}
class MockRoutineRepository extends Mock implements RoutineRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockSessionRepository mockSessionRepo;
  late MockRoutineRepository mockRoutineRepo;
  late MockHistoryRepository mockHistoryRepo;
  late RecoverSessionUseCase recoverSession;

  final routine = Routine(
    id: 'routine-123',
    name: 'Morning Yoga',
    alarms: [
      const Alarm(id: 'a1', durationSeconds: 60, orderIndex: 0),
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
    registerFallbackValue(const Duration(days: 180));
  });

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    mockRoutineRepo = MockRoutineRepository();
    mockHistoryRepo = MockHistoryRepository();
    recoverSession = RecoverSessionUseCase(
      sessionRepository: mockSessionRepo,
      routineRepository: mockRoutineRepo,
      historyRepository: mockHistoryRepo,
    );
  });

  group('RecoverSessionUseCase (Standard 6.2)', () {
    test('should return session as-is if it is fresh (< 24 hours)', () async {
      final freshSession = ActiveSession(
        routineId: routine.id,
        sessionStartTime: DateTime.now().subtract(const Duration(hours: 1)),
        anchorTime: DateTime.now().subtract(const Duration(hours: 1)),
        status: SessionStatus.running,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(freshSession));

      final result = await recoverSession.execute();

      expect(result.isSuccess, true);
      expect(result.success, freshSession);
      verifyNever(() => mockHistoryRepo.saveRun(any()));
      verifyNever(() => mockSessionRepo.clearSession());
    });

    test('should recover and clear zombie session (> 24 hours)', () async {
      final zombieSession = ActiveSession(
        routineId: routine.id,
        sessionStartTime: DateTime.now().subtract(const Duration(hours: 25)),
        anchorTime: DateTime.now().subtract(const Duration(hours: 25)),
        status: SessionStatus.running,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(zombieSession));
      when(() => mockRoutineRepo.getAllRoutines()).thenAnswer((_) async => Result.success([routine]));
      when(() => mockHistoryRepo.saveRun(any())).thenAnswer((_) async => const Result.success(null));
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async => const Result.success(null));

      final result = await recoverSession.execute();

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.inactive);
      
      // Verify history persistence for the abandoned session
      final capturedRun = verify(() => mockHistoryRepo.saveRun(captureAny())).captured.single as RoutineRun;
      expect(capturedRun.routineId, routine.id);
      expect(capturedRun.status, RunStatus.stopped);
      
      // Verify session clearing
      verify(() => mockSessionRepo.clearSession()).called(1);
    });

    test('should return inactive session if no session persisted', () async {
      const inactiveSession = ActiveSession();
      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => const Result.success(inactiveSession));

      final result = await recoverSession.execute();

      expect(result.isSuccess, true);
      expect(result.success, inactiveSession);
    });
  });
}
