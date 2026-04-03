import 'package:hive/hive.dart';
import '../../domain/entities/routine_run.dart';

part 'routine_run_model.g.dart';

/// Routine Run Model - Hive persistence object for RoutineRun.
/// // Fulfills INT-15
@HiveType(typeId: 3)
class RoutineRunModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String routineId;

  @HiveField(2)
  final String routineName;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final String statusName;

  RoutineRunModel({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startTime,
    required this.endTime,
    required this.statusName,
  });

  /// Convert from Domain Entity to Data Model
  factory RoutineRunModel.fromEntity(RoutineRun run) {
    return RoutineRunModel(
      id: run.id,
      routineId: run.routineId,
      routineName: run.routineName,
      startTime: run.startTime,
      endTime: run.endTime,
      statusName: run.status.name,
    );
  }

  /// Convert from Data Model to Domain Entity
  RoutineRun toEntity() {
    return RoutineRun(
      id: id,
      routineId: routineId,
      routineName: routineName,
      startTime: startTime,
      endTime: endTime,
      status: RunStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => RunStatus.stopped,
      ),
    );
  }
}
