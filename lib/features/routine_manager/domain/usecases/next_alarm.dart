import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';

import '../services/notification_service.dart';

part 'next_alarm.g.dart';

/// Next Alarm Use Case - Pure Dart logic to advance to the next alarm or complete.
/// // Fulfills INT-03, INT-11
class NextAlarmUseCase {
  final NotificationService notificationService;

  NextAlarmUseCase({
    required this.notificationService,
  });

  Future<ActiveSession> execute({
    required Routine routine,
    required ActiveSession currentSession,
  }) async {
    // 1. Cancel ongoing native notification alarm
    await notificationService.cancelAll();

    final nextIndex = currentSession.activeAlarmIndex + 1;

    // 2. Completion Check (INT-11)
    if (nextIndex >= routine.alarms.length) {
      return currentSession.copyWith(
        activeAlarmIndex: currentSession.activeAlarmIndex,
        status: SessionStatus.completed,
      );
    }

    // 3. Move to next alarm
    final nextSession = currentSession.copyWith(
      activeAlarmIndex: nextIndex,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
      status: SessionStatus.running,
    );

    // 4. Schedule next alarm notification (INT-07)
    final nextAlarm = routine.alarms[nextIndex];
    await notificationService.scheduleNotification(
      id: routine.id.hashCode ^ nextIndex,
      title: "Routine: ${routine.name}",
      body: "Alarm ${nextIndex + 1} is complete!",
      scheduledDate: DateTime.now().add(Duration(seconds: nextAlarm.durationSeconds)),
    );

    return nextSession;
  }
}

@riverpod
NextAlarmUseCase nextAlarmUseCase(NextAlarmUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NextAlarmUseCase(
    notificationService: notificationService,
  );
}
