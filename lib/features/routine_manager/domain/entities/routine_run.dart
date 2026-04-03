import 'package:equatable/equatable.dart';

/// Status of the routine execution.
/// // Fulfills INT-15
enum RunStatus {
  completed,
  stopped,
}

/// Routine Run Entity - Represents a captured snapshot of a routine performance.
/// // Fulfills INT-15, INT-16, INT-17
class RoutineRun extends Equatable {
  final String id;
  final String routineId;
  final String routineName;
  final DateTime startTime;
  final DateTime endTime;
  final RunStatus status;

  const RoutineRun({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  @override
  List<Object?> get props => [id, routineId, routineName, startTime, endTime, status];

  /// Duration calculated from start and end times.
  Duration get totalDuration => endTime.difference(startTime);

  RoutineRun copyWith({
    String? id,
    String? routineId,
    String? routineName,
    DateTime? startTime,
    DateTime? endTime,
    RunStatus? status,
  }) {
    return RoutineRun(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}
