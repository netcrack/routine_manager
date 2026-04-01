import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/entities/routine.dart';
import '../../domain/usecases/next_alarm.dart';
import '../../domain/usecases/pause_session.dart';
import '../../domain/usecases/resume_session.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/stop_session.dart';
import '../../../../core/di/service_providers.dart';
import 'routine_list_controller.dart';

part 'active_session_controller.g.dart';

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
    if (savedSession != null) {
      state = savedSession;
      if (state.status == SessionStatus.running) {
        _recoverState();
      }
    }
  }

  /// Start a routine session
  /// // Fulfills INT-03, INT-09
  Future<void> startRoutine(Routine routine) async {
    final startUseCase = ref.read(startSessionUseCaseProvider);
    
    try {
      final session = await startUseCase.execute(
        routine: routine,
        currentSession: state,
      );
      
      state = session;
      await _saveState();
      _startTimer();
    } catch (e) {
      // Handle permission errors or singleton violation
      rethrow;
    }
  }

  /// Stop current session permanently
  /// // Fulfills INT-05
  Future<void> stopSession() async {
    final stopUseCase = ref.read(stopSessionUseCaseProvider);
    state = await stopUseCase.execute();
    await ref.read(sessionRepositoryProvider).clearSession();
    _timer?.cancel();
  }

  /// Pause the timer
  /// // Fulfills INT-06
  Future<void> pauseSession() async {
    if (state.status != SessionStatus.running) return;
    
    final pauseUseCase = ref.read(pauseSessionUseCaseProvider);
    state = await pauseUseCase.execute(state);
    await _saveState();
    _timer?.cancel();
  }

  /// Resume the timer
  /// // Fulfills INT-06
  Future<void> resumeSession() async {
    if (state.status != SessionStatus.paused) return;

    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final resumeUseCase = ref.read(resumeSessionUseCaseProvider);
    state = await resumeUseCase.execute(routine: routine, currentSession: state);
    await _saveState();
    _startTimer();
  }

  /// Move to the next alarm or finish
  /// // Fulfills INT-03, INT-11
  Future<void> nextAlarm() async {
    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final nextUseCase = ref.read(nextAlarmUseCaseProvider);
    state = await nextUseCase.execute(routine: routine, currentSession: state);
    await _saveState();

    if (state.status == SessionStatus.running) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    // Use a faster tick to reduce UI update delay when crossing the second boundary
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _tick();
    });
  }

  void _tick() async {
    if (state.status != SessionStatus.running) return;

    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final currentAlarm = routine.alarms[state.activeAlarmIndex];
    final startTime = state.startTime;
    if (startTime == null) return;

    final now = DateTime.now();
    final realElapsedSinceStart = now.difference(startTime).inSeconds;
    
    // Only update state if at least 1 second has elapsed
    if (realElapsedSinceStart < 1) return;
    final totalElapsed = state.elapsedSeconds + realElapsedSinceStart;

    if (totalElapsed >= currentAlarm.durationSeconds) {
      // Alarm Finished! (INT-03)
      _timer?.cancel();
      
      state = state.copyWith(
        elapsedSeconds: currentAlarm.durationSeconds,
        status: SessionStatus.ringing,
      );
      _saveState();
    } else {
      // Advance startTime by EXACTLY the number of seconds we added to preserve the fractional remainder
      final newStartTime = startTime.add(Duration(seconds: realElapsedSinceStart));
      state = state.copyWith(
        elapsedSeconds: totalElapsed, 
        startTime: newStartTime,
      );
      _saveState();
    }
  }

  Routine? _getCurrentRoutine() {
    final routines = ref.read(routineListProvider).value ?? [];
    return routines.firstWhere((r) => r.id == state.routineId);
  }

  /// Recover state from background or relaunch
  /// // Fulfills INT-07, Core Standard 6.2
  void _recoverState() {
    if (state.status != SessionStatus.running) return;

    final routine = _getCurrentRoutine();
    if (routine == null) return;

    final currentAlarm = routine.alarms[state.activeAlarmIndex];
    final startTime = state.startTime;
    if (startTime == null) return;

    final now = DateTime.now();
    final realElapsedSinceStart = now.difference(startTime).inSeconds;
    final totalElapsed = state.elapsedSeconds + realElapsedSinceStart;

    if (totalElapsed >= currentAlarm.durationSeconds) {
      // Alarm Finished while in background!
      _timer?.cancel();
      state = state.copyWith(
        elapsedSeconds: currentAlarm.durationSeconds,
        status: SessionStatus.ringing,
      );
      _saveState();
    } else {
      // Still running, update the tick and preserve fractional remainder
      final newStartTime = startTime.add(Duration(seconds: realElapsedSinceStart));
      state = state.copyWith(
        elapsedSeconds: totalElapsed, 
        startTime: newStartTime,
      );
      _saveState();
      _startTimer();
    }
  }

  Future<void> _saveState() async {
    await ref.read(sessionRepositoryProvider).saveSession(state);
  }
}
