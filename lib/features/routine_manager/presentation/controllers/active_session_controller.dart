import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/entities/routine.dart';
import '../../domain/usecases/next_alarm.dart';
import '../../domain/usecases/pause_session.dart';
import '../../domain/usecases/process_heartbeat.dart';
import '../../domain/usecases/resume_session.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/stop_session.dart';
import 'routine_list_controller.dart';

part 'active_session_controller.g.dart';

/// Active Session Controller - Central state holder for the running routine session.
/// // Fulfills INT-03, INT-05, INT-06, INT-09, INT-11
@Riverpod(keepAlive: true)
class ActiveSessionController extends _$ActiveSessionController {
  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;

  @override
  ActiveSession build() {
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (lifecycleState) {
        if (lifecycleState == AppLifecycleState.resumed) {
          _recoverState();
        }
      },
    );
    
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycleListener?.dispose();
    });
    
    // Asynchronously load the persisted state
    _loadPersistedState();
    
    return const ActiveSession();
  }

  Future<void> _loadPersistedState() async {
    final repo = ref.read(sessionRepositoryProvider);
    final savedSession = await repo.loadSession();
    state = savedSession;
    if (state.status == SessionStatus.running) {
      _recoverState();
    }
  }

  /// Start a routine session
  /// // Fulfills INT-03, INT-09, Standard 5.1 & 5.3
  Future<void> startRoutine(Routine routine) async {
    final startUseCase = ref.read(startSessionUseCaseProvider);
    
    final result = await startUseCase.execute(routine);
    
    result.when(
      onSuccess: (session) {
        state = session;
        _startTimer();
      },
      onFailure: (error) {
        // Presentation layer handles the failure state
      },
    );
  }

  /// Stop current session permanently
  /// // Fulfills INT-05, Standard 5.3
  Future<void> stopSession() async {
    final stopUseCase = ref.read(stopSessionUseCaseProvider);
    final result = await stopUseCase.execute();
    
    result.when(
      onSuccess: (session) {
        state = session;
        _timer?.cancel();
      },
      onFailure: (error) {},
    );
  }

  /// Pause the timer
  /// // Fulfills INT-06
  Future<void> pauseSession() async {
    final pauseUseCase = ref.read(pauseSessionUseCaseProvider);
    final result = await pauseUseCase.execute();
    
    result.when(
      onSuccess: (session) {
        state = session;
        _timer?.cancel();
      },
      onFailure: (_) {},
    );
  }

  /// Resume the timer
  /// // Fulfills INT-06
  Future<void> resumeSession() async {
    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final resumeUseCase = ref.read(resumeSessionUseCaseProvider);
    final result = await resumeUseCase.execute(routine);
    
    result.when(
      onSuccess: (session) {
        state = session;
        _startTimer();
      },
      onFailure: (_) {},
    );
  }

  /// Move to the next alarm or finish
  /// // Fulfills INT-03, INT-11
  Future<void> nextAlarm() async {
    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final nextUseCase = ref.read(nextAlarmUseCaseProvider);
    final result = await nextUseCase.execute(routine);
    
    result.when(
      onSuccess: (session) {
        state = session;
        if (state.status == SessionStatus.running) {
          _startTimer();
        } else {
          _timer?.cancel();
        }
      },
      onFailure: (_) {},
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _tick();
    });
  }

  void _tick() async {
    if (state.status != SessionStatus.running) {
      _timer?.cancel();
      return;
    }

    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final result = await ref.read(processHeartbeatUseCaseProvider).execute(routine);

    result.when(
      onSuccess: (updatedSession) {
        state = updatedSession;
        if (state.status != SessionStatus.running) {
          _timer?.cancel();
        }
      },
      onFailure: (_) {
         _timer?.cancel();
      },
    );
  }

  Routine? _getCurrentRoutine() {
    final routines = ref.read(routineListProvider).value ?? [];
    return routines.firstWhere((r) => r.id == state.routineId);
  }

  /// Recover state from background or relaunch
  /// // Fulfills INT-07, Core Standard 6.2
  void _recoverState() {
    if (state.status != SessionStatus.running) return;
    _tick(); // Immediately trigger a heartbeat to sync state
  }
}
