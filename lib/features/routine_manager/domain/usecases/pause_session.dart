import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';

part 'pause_session.g.dart';

/// Pause Session Use Case - Enforces atomic transition to paused state.
/// // Fulfills INT-06, Standard 4.2 (Atomicity)
class PauseSessionUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;

  PauseSessionUseCase({
    required this.notificationService,
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute() async {
    // 1. Read: Load the current Persistence state (Standard 4.2)
    final session = await sessionRepository.loadSession();

    // 2. Validate: Must be running to pause
    if (session.status != SessionStatus.running) {
      return Result.success(session); // Idempotent: No change if not running
    }

    // 4. Side Effect: Cancel the notification as the end time is no longer valid
    await notificationService.cancelAll();

    // 5. Apply: Transition to paused AND save accumulated progress
    final now = DateTime.now();
    final startTime = session.startTime;
    int totalElapsed = session.elapsedSeconds;
    
    if (startTime != null) {
      totalElapsed += now.difference(startTime).inSeconds;
    }

    final updatedSession = session.copyWith(
      status: SessionStatus.paused,
      elapsedSeconds: totalElapsed,
    );

    // 6. Persist: Commit the final state (Standard 4.2)
    await sessionRepository.saveSession(updatedSession);

    return Result.success(updatedSession);
  }
}

@riverpod
PauseSessionUseCase pauseSessionUseCase(PauseSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return PauseSessionUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
  );
}
