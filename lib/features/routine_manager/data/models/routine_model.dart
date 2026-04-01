import 'package:hive/hive.dart';
import '../../domain/entities/routine.dart';
import 'alarm_model.dart';

part 'routine_model.g.dart';

/// Routine Model - Hive persistence object for Routine.
/// // Fulfills INT-01, INT-04, INT-10
@HiveType(typeId: 1)
class RoutineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<AlarmModel> alarms;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  RoutineModel({
    required this.id,
    required this.name,
    required this.alarms,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Domain Entity to Data Model
  factory RoutineModel.fromEntity(Routine routine) {
    return RoutineModel(
      id: routine.id,
      name: routine.name,
      alarms: routine.alarms.map((e) => AlarmModel.fromEntity(e)).toList(),
      createdAt: routine.createdAt,
      updatedAt: routine.updatedAt,
    );
  }

  /// Convert from Data Model to Domain Entity
  Routine toEntity() {
    return Routine(
      id: id,
      name: name,
      alarms: alarms.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
