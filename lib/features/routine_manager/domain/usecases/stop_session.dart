import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';

part 'stop_session.g.dart';

/// Stop Session Use Case - Enforces atomic termination of an active session.
/// // Fulfills INT-05, Standard 4.2 (Atomicity)
class StopSessionUseCase {
  final NotificationService notificationService;
  final SessionRepository sessionRepository;

  StopSessionUseCase({
    required this.notificationService,
    required this.sessionRepository,
  });

  Future<Result<ActiveSession, DomainError>> execute() async {
    // 1. Side Effect: Cancel all notifications & continuous ringing (INT-08)
    await notificationService.cancelAll();

    // 2. Persist: Clear the session from storage (Standard 4.2, INT-09 lock release)
    await sessionRepository.clearSession();

    // 3. Apply: Return a clean inactive state
    return const Result.success(ActiveSession());
  }
}

@riverpod
StopSessionUseCase stopSessionUseCase(StopSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return StopSessionUseCase(
    notificationService: notificationService,
    sessionRepository: sessionRepository,
  );
}
