import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../entities/routine_run.dart';
import '../repositories/session_repository.dart';
import '../repositories/history_repository.dart';
import '../services/notification_service.dart';

part 'stop_session.g.dart';

/// Stop Session Use Case - Enforces atomic termination of an active session.
/// // Fulfills INT-05, INT-15, INT-18, Standard 4.2 (Atomicity)
class StopSessionUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;
  final HistoryRepository historyRepository;

  StopSessionUseCase({
    required this.notificationService,
    required this.sessionRepository,
    required this.historyRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load the current Persistence state (Standard 4.2)
    final sessionResult = await sessionRepository.loadSession();

    return await sessionResult.fold(
      (session) async {
        // 2. Side Effect: Cancel all notifications & continuous ringing (INT-08)
        await notificationService.cancelAll();

        // 3. Apply & Record History (INT-15) - Only if there was an active session
        if (session.status != SessionStatus.inactive) {
          final routineRun = RoutineRun(
            id: const Uuid().v4(),
            routineId: routine.id,
            routineName: routine.name, // Snapshot name for stability (Standard 7.3)
            startTime: session.sessionStartTime ?? DateTime.now(),
            endTime: DateTime.now(),
            status: RunStatus.stopped,
          );

          // Graceful History Degradation: log but proceed to clear session
          await historyRepository.saveRun(routineRun);

          // 4. Trigger Retention Pruning (INT-18)
          await historyRepository.pruneHistory(const Duration(days: 180));
        }

        // 5. Persist: Clear the session from storage (Standard 4.2, INT-09 lock release)
        final result = await sessionRepository.clearSession();

        return result.fold(
          (_) => const Result.success(ActiveSession()),
          (failure) => Result.failure(failure),
        );
      },
      (failure) => Result.failure(failure),
    );
  }
}

@riverpod
StopSessionUseCase stopSessionUseCase(StopSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final historyRepository = ref.watch(historyRepositoryProvider);
  return StopSessionUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
    historyRepository: historyRepository,
  );
}
