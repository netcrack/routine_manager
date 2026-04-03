import 'package:equatable/equatable.dart';

/// Session Status - Current state of the active routine session.
/// // Fulfills INT-03, INT-06, INT-11
enum SessionStatus {
  inactive,
  running,
  paused,
  ringing,
}

/// Active Session Entity - Represent the state of an ongoing routine execution.
/// // Fulfills INT-03, INT-06, INT-11
class ActiveSession extends Equatable {
  final String routineId;
  final int activeAlarmIndex;
  final int elapsedSeconds;
  final DateTime? sessionStartTime;
  final DateTime? anchorTime;
  final SessionStatus status;

  const ActiveSession({
    this.routineId = '',
    this.activeAlarmIndex = 0,
    this.elapsedSeconds = 0,
    this.sessionStartTime,
    this.anchorTime,
    this.status = SessionStatus.inactive,
  });

  @override
  List<Object?> get props => [
        routineId,
        activeAlarmIndex,
        elapsedSeconds,
        sessionStartTime,
        anchorTime,
        status,
      ];

  ActiveSession copyWith({
    String? routineId,
    int? activeAlarmIndex,
    int? elapsedSeconds,
    DateTime? sessionStartTime,
    DateTime? anchorTime,
    SessionStatus? status,
  }) {
    return ActiveSession(
      routineId: routineId ?? this.routineId,
      activeAlarmIndex: activeAlarmIndex ?? this.activeAlarmIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      anchorTime: anchorTime ?? this.anchorTime,
      status: status ?? this.status,
    );
  }

  /// Initial state for a specific routine
  factory ActiveSession.initial(String routineId) {
    final now = DateTime.now();
    return ActiveSession(
      routineId: routineId,
      activeAlarmIndex: 0,
      elapsedSeconds: 0,
      sessionStartTime: now,
      anchorTime: now,
      status: SessionStatus.running,
    );
  }
}
