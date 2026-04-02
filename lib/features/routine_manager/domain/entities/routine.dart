import 'package:equatable/equatable.dart';
import 'alarm.dart';

/// Routine Entity - Pure Dart logic representing a collection of Alarms.
/// // Fulfills INT-01, INT-04, INT-10
class Routine extends Equatable {
  final String id;
  final String name;
  final List<Alarm> alarms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Routine({
    required this.id,
    required this.name,
    required this.alarms,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, alarms, createdAt, updatedAt];

  Routine copyWith({
    String? id,
    String? name,
    List<Alarm>? alarms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      alarms: alarms ?? this.alarms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Bulk updates all alarms in this routine to the specified duration.
  /// // Fulfills INT-14
  Routine updateAllAlarmDurations(int durationSeconds) {
    final updatedAlarms = alarms.map((alarm) {
      return alarm.copyWith(durationSeconds: durationSeconds);
    }).toList();

    return copyWith(
      alarms: updatedAlarms,
      updatedAt: DateTime.now(),
    );
  }
}
