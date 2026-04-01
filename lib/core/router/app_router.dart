import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/routine_manager/domain/entities/routine.dart';
import '../../features/routine_manager/presentation/screens/active_session_screen.dart';
import '../../features/routine_manager/presentation/screens/routine_builder_screen.dart';
import '../../features/routine_manager/presentation/screens/routine_list_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoutineListScreen(),
      ),
      GoRoute(
        path: '/builder',
        builder: (context, state) {
          final routine = state.extra as Routine?;
          return RoutineBuilderScreen(initialRoutine: routine);
        },
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) => const ActiveSessionScreen(),
      ),
    ],
  );
}
