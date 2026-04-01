import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/active_session.dart';
import '../services/notification_service.dart';
import '../../../../core/di/service_providers.dart';

part 'pause_session.g.dart';

/// Pause Session Use Case - Pure Dart logic to pause an active routine execution.
/// // Fulfills INT-06
class PauseSessionUseCase {
  final NotificationService notificationService;

  PauseSessionUseCase({required this.notificationService});

  Future<ActiveSession> execute(ActiveSession currentSession) async {
    if (currentSession.status != SessionStatus.running) {
      return currentSession;
    }

    // Cancel the notification as the end time is no longer valid
    await notificationService.cancelAll();

    return currentSession.copyWith(status: SessionStatus.paused);
  }
}

@riverpod
PauseSessionUseCase pauseSessionUseCase(PauseSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return PauseSessionUseCase(notificationService: notificationService);
}
