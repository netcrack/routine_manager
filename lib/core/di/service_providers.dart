import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/routine_manager/domain/services/notification_service.dart';
import '../../features/routine_manager/domain/repositories/session_repository.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  // Overridden in ProviderScope
  throw UnimplementedError('NotificationService must be provided');
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(SessionRepositoryRef ref) {
  // Overridden in ProviderScope
  throw UnimplementedError('SessionRepository must be provided');
}

@riverpod
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin(FlutterLocalNotificationsPluginRef ref) {
  return FlutterLocalNotificationsPlugin();
}
