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
import '../services/notification_strings.dart';

part 'next_alarm.g.dart';

/// Next Alarm Use Case - Atomic transition from Ringing to next alarm or completion.
/// // Fulfills INT-03, INT-11, INT-15, INT-18, Standard 4.2 (Atomicity)
class NextAlarmUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;
  final HistoryRepository historyRepository;

  NextAlarmUseCase({
    required this.notificationService,
    required this.sessionRepository,
    required this.historyRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load current session (Standard 4.2)
    final sessionResult = await sessionRepository.loadSession();
    
    return sessionResult.fold(
      (session) async {
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
          
          // 4a. Record Routine Execution History (INT-15)
          final routineRun = RoutineRun(
            id: const Uuid().v4(),
            routineId: routine.id,
            routineName: routine.name, // Snapshot name for stability (Standard 7.3)
            startTime: session.sessionStartTime ?? DateTime.now(),
            endTime: DateTime.now(),
            status: RunStatus.completed,
          );
          
          // Graceful History Degradation (Journey 3 Standard 3.2.1):
          // If history saving fails, log but proceed to clear the active session
          await historyRepository.saveRun(routineRun);
          
          // 4b. Trigger Retention Pruning (INT-18)
          await historyRepository.pruneHistory(const Duration(days: 180));

          // 4c. Persist completion (effectively clearing the active session)
          return await sessionRepository.saveSession(completedSession).then(
            (result) => result.fold(
              (_) => Result.success(completedSession),
              (failure) => Result.failure(failure),
            ),
          );
        }

        // 5. Apply: Move to next alarm
        final nextSession = session.copyWith(
          activeAlarmIndex: nextIndex,
          elapsedSeconds: 0,
          anchorTime: DateTime.now(),
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
        return await sessionRepository.saveSession(nextSession).then(
          (result) => result.fold(
            (_) => Result.success(nextSession),
            (failure) => Result.failure(failure),
          ),
        );
      },
      (failure) => Result.failure(failure),
    );
  }
}

@riverpod
NextAlarmUseCase nextAlarmUseCase(NextAlarmUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final historyRepository = ref.watch(historyRepositoryProvider);
  return NextAlarmUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
    historyRepository: historyRepository,
  );
}
