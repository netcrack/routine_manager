import 'package:equatable/equatable.dart';

/// Session Status - Current state of the active routine session.
/// // Fulfills INT-03, INT-06, INT-11
enum SessionStatus {
  inactive,
  running,
  paused,
  ringing,
  completed,
}

/// Active Session Entity - Represent the state of an ongoing routine execution.
/// // Fulfills INT-03, INT-06, INT-11
class ActiveSession extends Equatable {
  final String routineId;
  final int activeAlarmIndex;
  final int elapsedSeconds;
  final DateTime? startTime;
  final SessionStatus status;

  const ActiveSession({
    this.routineId = '',
    this.activeAlarmIndex = 0,
    this.elapsedSeconds = 0,
    this.startTime,
    this.status = SessionStatus.inactive,
  });

  @override
  List<Object?> get props => [routineId, activeAlarmIndex, elapsedSeconds, startTime, status];

  ActiveSession copyWith({
    String? routineId,
    int? activeAlarmIndex,
    int? elapsedSeconds,
    DateTime? startTime,
    SessionStatus? status,
  }) {
    return ActiveSession(
      routineId: routineId ?? this.routineId,
      activeAlarmIndex: activeAlarmIndex ?? this.activeAlarmIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
    );
  }

  /// Initial state for a specific routine
  factory ActiveSession.initial(String routineId) {
    return ActiveSession(
      routineId: routineId,
      activeAlarmIndex: 0,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
      status: SessionStatus.running,
    );
  }
}
