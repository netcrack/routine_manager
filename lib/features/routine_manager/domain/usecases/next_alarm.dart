import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

part 'next_alarm.g.dart';

/// Next Alarm Use Case - Atomic transition from Ringing to next alarm or completion.
/// // Fulfills INT-03, INT-11, Standard 4.2 (Atomicity)
class NextAlarmUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;

  NextAlarmUseCase({
    required this.notificationService,
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load current session (Standard 4.2)
    final session = await sessionRepository.loadSession();

    // 2. Validate: Must be ringing or running to skip/next
    if (session.status == SessionStatus.inactive) {
      return Result.success(session);
    }

    // 3. Side Effect: Cancel ongoing native notification alarm
    await notificationService.cancelAll();

    final nextIndex = session.activeAlarmIndex + 1;

    // 4. Completion Check (INT-11)
    if (nextIndex >= routine.alarms.length) {
      const completedSession = ActiveSession(); // Defaults to status: inactive, empty IDs
      
      // Persist completion (effectively clearing the active session)
      await sessionRepository.saveSession(completedSession);
      
      return Result.success(completedSession);
    }

    // 5. Apply: Move to next alarm
    final nextSession = session.copyWith(
      activeAlarmIndex: nextIndex,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
      status: SessionStatus.running,
    );

    // 6. Side Effect: Schedule next alarm notification (INT-07)
    final nextAlarm = routine.alarms[nextIndex];
    await notificationService.scheduleNotification(
      id: routine.id.hashCode ^ nextIndex,
      title: NotificationStrings.routineTitle(routine.name),
      body: NotificationStrings.alarmBody(nextIndex, routine.alarms.length),
      scheduledDate: DateTime.now().add(Duration(seconds: nextAlarm.durationSeconds)),
      payload: 'active_session',
    );

    // 7. Persist: Commit final state (Standard 4.2)
    await sessionRepository.saveSession(nextSession);

    return Result.success(nextSession);
  }
}

@riverpod
NextAlarmUseCase nextAlarmUseCase(NextAlarmUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return NextAlarmUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
  );
}
