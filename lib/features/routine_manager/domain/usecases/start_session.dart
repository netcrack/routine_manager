import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../entities/active_session.dart';
import '../entities/routine.dart';
import '../services/notification_service.dart';

part 'start_session.g.dart';

/// Start Session Use Case - Pure Dart logic to initiate a routine execution.
/// // Fulfills INT-03, INT-09
class StartSessionUseCase {
  final NotificationService notificationService;

  StartSessionUseCase({required this.notificationService});

  Future<ActiveSession> execute({
    required Routine routine,
    required ActiveSession currentSession,
  }) async {
    // 1. Enforce Singleton Execution (INT-09)
    if (currentSession.status != SessionStatus.inactive) {
      throw StateError('Cannot start a new session while another is active.');
    }

    // 2. Permission Check (INT-09)
    var hasPermissions = await notificationService.checkPermissions();
    if (!hasPermissions) {
      hasPermissions = await notificationService.requestPermissions();
    }
    if (!hasPermissions) {
      throw StateError('Notification permissions are required to start a session.');
    }

    // 3. Clear any old notifications
    await notificationService.cancelAll();

    // 4. Initial Active Session state
    final session = ActiveSession.initial(routine.id);

    // 5. Schedule first alarm notification (INT-07)
    final firstAlarm = routine.alarms[0];
    await notificationService.scheduleNotification(
      id: routine.id.hashCode ^ 0,
      title: "Routine: ${routine.name}",
      body: "First alarm is complete!",
      scheduledDate: DateTime.now().add(Duration(seconds: firstAlarm.durationSeconds)),
    );

    return session;
  }
}

@riverpod
StartSessionUseCase startSessionUseCase(StartSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return StartSessionUseCase(notificationService: notificationService);
}
