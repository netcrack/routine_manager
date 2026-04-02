import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../di/service_providers.dart';

part 'notification_click_provider.g.dart';

@riverpod
Stream<String?> notificationClick(NotificationClickRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.onNotificationClick;
}
