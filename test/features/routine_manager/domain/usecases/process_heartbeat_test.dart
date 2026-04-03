// Verifies INT-02, INT-03, INT-07 (Standard 8.4)
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/result.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/session_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/process_heartbeat.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockSessionRepo;
  late ProcessHeartbeatUseCase processHeartbeat;

  final routine = Routine(
    id: '1',
    name: 'Yoga',
    alarms: [
      const Alarm(id: 'a1', durationSeconds: 10, orderIndex: 0),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(const ActiveSession());
  });

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    processHeartbeat = ProcessHeartbeatUseCase(
      sessionRepository: mockSessionRepo,
    );
  });

  group('ProcessHeartbeatUseCase (Fixed Anchor Logic)', () {
    test('should transition to ringing when exactly duration has passed (Wall-Clock)', () async {
      final startTime = DateTime.now().subtract(const Duration(seconds: 10));
      final session = ActiveSession(
        routineId: '1',
        activeAlarmIndex: 0,
        elapsedSeconds: 0,
        anchorTime: startTime,
        sessionStartTime: startTime,
        status: SessionStatus.running,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(session));
      when(() => mockSessionRepo.saveSession(any())).thenAnswer((_) async => const Result.success(null));

      final result = await processHeartbeat.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.status, SessionStatus.ringing);
      expect(result.success.elapsedSeconds, 10);
      
      verify(() => mockSessionRepo.saveSession(any(that: predicate((s) => (s as ActiveSession).status == SessionStatus.ringing)))).called(1);
    });

    test('should return projected elapsed time for UI sync without saving to Hive (Frozen Anchor)', () async {
      final startTime = DateTime.now().subtract(const Duration(seconds: 5));
      final session = ActiveSession(
        routineId: '1',
        activeAlarmIndex: 0,
        elapsedSeconds: 0,
        anchorTime: startTime,
        sessionStartTime: startTime,
        status: SessionStatus.running,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(session));

      final result = await processHeartbeat.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.elapsedSeconds, 5);
      expect(result.success.anchorTime, startTime); // Anchor must NOT change
      
      // CRITICAL in Frozen Anchor: Heartbeat must NOT save to DB during the run
      // to avoid double-counting and truncation risk.
      verifyNever(() => mockSessionRepo.saveSession(any()));
    });

    test('should handle accumulated time from previous pause correctly', () async {
      final startTime = DateTime.now().subtract(const Duration(seconds: 5));
      final session = ActiveSession(
        routineId: '1',
        activeAlarmIndex: 0,
        elapsedSeconds: 3, // 3 seconds were banked before pause/resume
        anchorTime: startTime,
        sessionStartTime: startTime,
        status: SessionStatus.running,
      );

      when(() => mockSessionRepo.loadSession()).thenAnswer((_) async => Result.success(session));

      final result = await processHeartbeat.execute(routine);

      expect(result.isSuccess, true);
      expect(result.success.elapsedSeconds, 8); // 3 banked + 5 current
      expect(result.success.anchorTime, startTime);
    });
  });
}
