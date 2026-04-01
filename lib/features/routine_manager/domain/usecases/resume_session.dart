import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../services/notification_service.dart';
import '../../../../core/di/service_providers.dart';

part 'resume_session.g.dart';

/// Resume Session Use Case - Pure Dart logic to resume a paused routine execution.
/// // Fulfills INT-06
class ResumeSessionUseCase {
  final NotificationService notificationService;

  ResumeSessionUseCase({required this.notificationService});

  Future<ActiveSession> execute({
    required Routine routine,
    required ActiveSession currentSession,
  }) async {
    if (currentSession.status != SessionStatus.paused) {
      return currentSession;
    }

    final currentAlarm = routine.alarms[currentSession.activeAlarmIndex];
    final remainingSeconds = currentAlarm.durationSeconds - currentSession.elapsedSeconds;

    // Reschedule the notification for the remaining time
    await notificationService.scheduleNotification(
      id: routine.id.hashCode ^ currentSession.activeAlarmIndex,
      title: "Routine: ${routine.name}",
      body: "Alarm ${currentSession.activeAlarmIndex + 1} is resumed!",
      scheduledDate: DateTime.now().add(Duration(seconds: remainingSeconds)),
    );

    return currentSession.copyWith(
      status: SessionStatus.running,
      startTime: DateTime.now(),
    );
  }
}

@riverpod
ResumeSessionUseCase resumeSessionUseCase(ResumeSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ResumeSessionUseCase(notificationService: notificationService);
}
