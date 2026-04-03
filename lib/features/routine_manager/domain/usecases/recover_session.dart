import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../entities/routine_run.dart';
import '../repositories/routine_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/history_repository.dart';

part 'recover_session.g.dart';

/// Recover Session Use Case - Handles state recovery on app launch/resume and
/// detects "Zombie" sessions (Standard 6.2).
/// // Fulfills Standard 6.2, Standard 4.2
class RecoverSessionUseCase {
  final SessionRepository sessionRepository;
  final RoutineRepository routineRepository;
  final HistoryRepository historyRepository;

  RecoverSessionUseCase({
    required this.sessionRepository,
    required this.routineRepository,
    required this.historyRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute() async {
    // 1. Read: Load the persisted session (Standard 4.2)
    final sessionResult = await sessionRepository.loadSession();

    return await sessionResult.fold(
      (session) async {
        if (session.status == SessionStatus.inactive || session.sessionStartTime == null) {
          return Result.success(session);
        }

        // 2. Validate: Check for Zombie State (Standard 6.2)
        // Rule: If now > sessionStartTime + 24_HOURS, force terminate.
        final now = DateTime.now();
        final sessionAge = now.difference(session.sessionStartTime!);

        if (sessionAge > const Duration(hours: 24)) {
          // 3. Apply: Truncate and record history before clearing
          
          // We need the routine name for the history snapshot (Standard 7.3)
          final routinesResult = await routineRepository.getAllRoutines();
          final routine = routinesResult.fold(
            (routines) => routines.cast().firstWhere(
              (r) => r.id == session.routineId,
              orElse: () => null,
            ),
            (_) => null,
          );

          if (routine != null) {
            final abandonedRun = RoutineRun(
              id: const Uuid().v4(),
              routineId: routine.id,
              routineName: routine.name,
              startTime: session.sessionStartTime!,
              endTime: now,
              status: RunStatus.stopped,
            );
            await historyRepository.saveRun(abandonedRun);
          }

          // 4. Persist: Clear the session lock (INT-09)
          await sessionRepository.clearSession();
          return const Result.success(ActiveSession());
        }

        // Session is still fresh, return as is
        return Result.success(session);
      },
      (failure) => Result.failure(failure),
    );
  }
}

@riverpod
RecoverSessionUseCase recoverSessionUseCase(RecoverSessionUseCaseRef ref) {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final routineRepository = ref.watch(routineRepositoryProvider);
  final historyRepository = ref.watch(historyRepositoryProvider);
  
  return RecoverSessionUseCase(
    sessionRepository: sessionRepository,
    routineRepository: routineRepository,
    historyRepository: historyRepository,
  );
}
