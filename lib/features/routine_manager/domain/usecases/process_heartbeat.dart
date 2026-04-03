import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../repositories/session_repository.dart';
import '../entities/routine.dart';

part 'process_heartbeat.g.dart';

/// Process Heartbeat Use Case - Atomic update of elapsed time and transition to ringing.
/// // Fulfills INT-02, INT-03, Standard 4.2 (Atomicity)
class ProcessHeartbeatUseCase {
  final SessionRepository sessionRepository;

  ProcessHeartbeatUseCase({
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load the current Persistence state (Standard 4.2)
    final sessionResult = await sessionRepository.loadSession();
    
    return sessionResult.fold(
      (session) async {
        if (session.status != SessionStatus.running) {
          return Result.success(session);
        }

        final currentAlarm = routine.alarms[session.activeAlarmIndex];
        final anchorTime = session.anchorTime;
        if (anchorTime == null) return Result.success(session);

        final now = DateTime.now();
        final realElapsedSinceAnchor = now.difference(anchorTime).inSeconds;
        final totalElapsed = (session.elapsedSeconds + realElapsedSinceAnchor).toInt();

        if (totalElapsed >= currentAlarm.durationSeconds) {
          // 1. Alarm Finished! Transition to ringing
          final ringingSession = session.copyWith(
            elapsedSeconds: currentAlarm.durationSeconds,
            status: SessionStatus.ringing,
          );
          
          // Persist the final transition to Hive
          return await sessionRepository.saveSession(ringingSession).then(
            (result) => result.fold(
              (_) => Result.success(ringingSession),
              (failure) => Result.failure(failure),
            ),
          );
        } else {
          // 2. Still running. 
          // CRITICAL: We do NOT save to Hive here. We preserve the original 
          // 'elapsedSeconds' and 'startTime' in persistence to avoid drift.
          // We return the "projected" session so the UI (Controller) stays in sync.
          return Result.success(session.copyWith(
            elapsedSeconds: totalElapsed,
          ));
        }
      },
      (failure) => Result.failure(failure),
    );
  }
}

@riverpod
ProcessHeartbeatUseCase processHeartbeatUseCase(ProcessHeartbeatUseCaseRef ref) {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return ProcessHeartbeatUseCase(sessionRepository: sessionRepository);
}
