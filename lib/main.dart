import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/di/service_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/local_notification_service_impl.dart';
import 'features/routine_manager/data/models/alarm_model.dart';
import 'features/routine_manager/data/models/routine_model.dart';
import 'features/routine_manager/data/models/active_session_model.dart';
import 'features/routine_manager/data/repositories/routine_repository_impl.dart';
import 'features/routine_manager/data/repositories/session_repository_impl.dart';
import 'features/routine_manager/domain/repositories/routine_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(RoutineModelAdapter());
  Hive.registerAdapter(ActiveSessionModelAdapter());
  
  final routinesBox = await Hive.openBox<RoutineModel>(RoutineRepositoryImpl.boxName);
  final sessionBox = await Hive.openBox<ActiveSessionModel>('active_session_box');

  // Initialize Notifications
  final plugin = FlutterLocalNotificationsPlugin();
  final notificationService = LocalNotificationServiceImpl(plugin);
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        routineRepositoryProvider.overrideWithValue(RoutineRepositoryImpl(routinesBox)),
        sessionRepositoryProvider.overrideWithValue(SessionRepositoryImpl(sessionBox)),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Routine Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
