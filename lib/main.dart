import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_providers.dart';
import 'core/di/notification_click_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/local_notification_service_impl.dart';
import 'features/routine_manager/data/models/alarm_model.dart';
import 'features/routine_manager/data/models/routine_model.dart';
import 'features/routine_manager/data/models/active_session_model.dart';
import 'features/routine_manager/data/repositories/routine_repository_impl.dart';
import 'features/routine_manager/data/repositories/session_repository_impl.dart';
import 'features/routine_manager/data/models/routine_run_model.dart';
import 'features/routine_manager/data/repositories/history_repository_impl.dart';
import 'features/routine_manager/domain/repositories/routine_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(RoutineModelAdapter());
  Hive.registerAdapter(ActiveSessionModelAdapter());
  Hive.registerAdapter(RoutineRunModelAdapter());
  
  final routinesBox = await Hive.openBox<RoutineModel>(RoutineRepositoryImpl.boxName);
  final sessionBox = await Hive.openBox<ActiveSessionModel>('active_session_box');
  final historyBox = await Hive.openBox<RoutineRunModel>(HistoryRepositoryImpl.boxName);

  // Initialize Notifications
  final plugin = FlutterLocalNotificationsPlugin();
  final notificationService = LocalNotificationServiceImpl(plugin);
  await notificationService.init();

  // Check if app was launched from a notification
  final initialNotification = await plugin.getNotificationAppLaunchDetails();
  final initialPayload = initialNotification?.notificationResponse?.payload;

  runApp(
    ProviderScope(
      overrides: [
        routineRepositoryProvider.overrideWithValue(RoutineRepositoryImpl(routinesBox)),
        sessionRepositoryProvider.overrideWithValue(SessionRepositoryImpl(sessionBox)),
        historyRepositoryProvider.overrideWithValue(HistoryRepositoryImpl(historyBox)),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: MyApp(initialPayload: initialPayload),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final String? initialPayload;
  const MyApp({super.key, this.initialPayload});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Handle initial payload after first frame
    if (widget.initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(widget.initialPayload);
      });
    }
  }

  void _handleNavigation(String? payload) {
    // Currently we always land in /session for any relevant notification
    // In future this can be parsed to handle deeper links
    ref.read(appRouterProvider).push('/session');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Listen for runtime notification clicks
    ref.listen(notificationClickProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        _handleNavigation(next.value);
      }
    });

    return MaterialApp.router(
      title: 'Routine Manager',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
