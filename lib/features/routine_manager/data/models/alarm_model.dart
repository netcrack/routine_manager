import 'package:hive/hive.dart';
import '../../domain/entities/alarm.dart';

part 'alarm_model.g.dart';

/// Alarm Model - Hive persistence object for Alarm.
/// // Fulfills INT-02, INT-04
@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int durationSeconds;

  @HiveField(2)
  final int orderIndex;

  AlarmModel({
    required this.id,
    required this.durationSeconds,
    required this.orderIndex,
  });

  /// Convert from Domain Entity to Data Model
  factory AlarmModel.fromEntity(Alarm alarm) {
    return AlarmModel(
      id: alarm.id,
      durationSeconds: alarm.durationSeconds,
      orderIndex: alarm.orderIndex,
    );
  }

  /// Convert from Data Model to Domain Entity
  Alarm toEntity() {
    return Alarm(
      id: id,
      durationSeconds: durationSeconds,
      orderIndex: orderIndex,
    );
  }
}
