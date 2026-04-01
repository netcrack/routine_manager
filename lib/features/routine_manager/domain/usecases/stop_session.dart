import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../entities/active_session.dart';

import '../services/notification_service.dart';

part 'stop_session.g.dart';

/// Stop Session Use Case - Pure Dart logic to end routine execution.
/// // Fulfills INT-05
class StopSessionUseCase {
  final NotificationService notificationService;

  StopSessionUseCase({
    required this.notificationService,
  });

  Future<ActiveSession> execute() async {
    // 1. Cancel all notifications
    await notificationService.cancelAll();

    // 2. Reset session
    return const ActiveSession();
  }
}

@riverpod
StopSessionUseCase stopSessionUseCase(StopSessionUseCaseRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return StopSessionUseCase(
    notificationService: notificationService,
  );
}
