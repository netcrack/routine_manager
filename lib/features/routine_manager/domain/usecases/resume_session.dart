import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

part 'resume_session.g.dart';

/// Resume Session Use Case - Enforces atomic transition to running state.
/// // Fulfills INT-06, Standard 4.2 (Atomicity)
class ResumeSessionUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;

  ResumeSessionUseCase({
    required this.notificationService,
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load the current Persistence state (Standard 4.2)
    final session = await sessionRepository.loadSession();

    // 2. Validate: Must be paused to resume
    if (session.status != SessionStatus.paused) {
      return Result.success(session); // Idempotent: No change if not paused
    }

    final currentAlarm = routine.alarms[session.activeAlarmIndex];
    final remainingSeconds = currentAlarm.durationSeconds - session.elapsedSeconds;

    // 3. Side Effect: Reschedule the notification for the remaining time (INT-07)
    await notificationService.scheduleNotification(
      id: routine.id.hashCode ^ session.activeAlarmIndex,
      title: NotificationStrings.routineTitle(routine.name),
      body: NotificationStrings.alarmBody(session.activeAlarmIndex, routine.alarms.length),
      scheduledDate: DateTime.now().add(Duration(seconds: remainingSeconds)),
      payload: 'active_session',
    );

    // 4. Apply: Transition to running
    final updatedSession = session.copyWith(
      status: SessionStatus.running,
      startTime: DateTime.now(),
    );

    // 5. Persist: Commit the final state (Standard 4.2)
    await sessionRepository.saveSession(updatedSession);

    return Result.success(updatedSession);
  }
}

@riverpod
ResumeSessionUseCase resumeSessionUseCase(ResumeSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return ResumeSessionUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
  );
}
