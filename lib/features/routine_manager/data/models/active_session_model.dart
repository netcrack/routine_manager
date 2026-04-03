import 'package:hive/hive.dart';
import '../../domain/entities/active_session.dart';

part 'active_session_model.g.dart';

/// Active Session Model - Hive persistence object for the current routine state.
/// // Fulfills INT-03, INT-05, INT-06, INT-11 (Persistence)
@HiveType(typeId: 2)
class ActiveSessionModel extends HiveObject {
  @HiveField(0)
  final String routineId;

  @HiveField(1)
  final int activeAlarmIndex;

  @HiveField(2)
  final int elapsedSeconds;

  @HiveField(3)
  final DateTime? anchorTime;

  @HiveField(4)
  final String statusName;

  @HiveField(5)
  final DateTime? sessionStartTime;

  ActiveSessionModel({
    required this.routineId,
    required this.activeAlarmIndex,
    required this.elapsedSeconds,
    this.anchorTime,
    required this.statusName,
    this.sessionStartTime,
  });

  /// Convert from Domain Entity to Data Model
  factory ActiveSessionModel.fromEntity(ActiveSession entity) {
    return ActiveSessionModel(
      routineId: entity.routineId,
      activeAlarmIndex: entity.activeAlarmIndex,
      elapsedSeconds: entity.elapsedSeconds,
      anchorTime: entity.anchorTime,
      statusName: entity.status.name,
      sessionStartTime: entity.sessionStartTime,
    );
  }

  /// Convert from Data Model to Domain Entity
  ActiveSession toEntity() {
    return ActiveSession(
      routineId: routineId,
      activeAlarmIndex: activeAlarmIndex,
      elapsedSeconds: elapsedSeconds,
      anchorTime: anchorTime,
      sessionStartTime: sessionStartTime,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => SessionStatus.inactive,
      ),
    );
  }
}
