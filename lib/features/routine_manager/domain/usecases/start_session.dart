import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

part 'start_session.g.dart';

/// Start Session Use Case - Enforces singleton execution and initiates routine sequence.
/// // Fulfills INT-03, INT-09, Standard 4.2 (Atomicity), Standard 5.1 (Result Pattern)
class StartSessionUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;

  StartSessionUseCase({
    required this.notificationService,
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute(Routine routine) async {
    // 1. Read: Load the current Persistence state (Standard 4.2)
    final sessionResult = await sessionRepository.loadSession();
    
    return sessionResult.fold(
      (currentSession) async {
        // 2. Validate: Enforce Singleton Execution (INT-09, Standard 5.2)
        if (currentSession.status != SessionStatus.inactive) {
          return const Result.failure(DomainError.activeSessionExists);
        }

        // 2b. Validate: Enforce Non-Empty Routine Invariant (Journey 3 Refactor)
        if (routine.alarms.isEmpty) {
          return const Result.failure(DomainError.invalidRoutine);
        }

        // 3. System Permission Validation (INT-09, Standard 5.2)
        var hasPermissions = await notificationService.checkPermissions();
        if (!hasPermissions) {
          hasPermissions = await notificationService.requestPermissions();
        }
        if (!hasPermissions) {
          return const Result.failure(DomainError.permissionDenied);
        }

        // 4. Apply: Clear state and transition to new session
        await notificationService.cancelAll();
        final session = ActiveSession.initial(routine.id);

        // 5. Side Effect: Schedule first alarm notification (INT-07)
        final firstAlarm = routine.alarms[0];
        await notificationService.scheduleNotification(
          id: routine.id.hashCode ^ 0,
          title: NotificationStrings.routineTitle(routine.name),
          body: NotificationStrings.alarmBody(0, routine.alarms.length),
          scheduledDate: DateTime.now().add(Duration(seconds: firstAlarm.durationSeconds)),
          payload: 'active_session',
        );

        // 6. Persist: Commit the final state to repository (Standard 4.2)
        return await sessionRepository.saveSession(session).then((result) => result.fold(
          (_) => Result.success(session),
          (failure) => Result.failure(failure),
        ));
      },
      (failure) => Result.failure(failure),
    );
  }
}

@riverpod
StartSessionUseCase startSessionUseCase(StartSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return StartSessionUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
  );
}
