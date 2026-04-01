import 'package:equatable/equatable.dart';

/// Alarm Entity - Pure Dart logic for a single timer in a routine.
/// // Fulfills INT-02, INT-04
class Alarm extends Equatable {
  final String id;
  final int durationSeconds;
  final int orderIndex;

  const Alarm({
    required this.id,
    required this.durationSeconds,
    required this.orderIndex,
  }) : assert(durationSeconds > 0, 'Duration must be greater than 0 seconds.');

  @override
  List<Object?> get props => [id, durationSeconds, orderIndex];

  Alarm copyWith({
    String? id,
    int? durationSeconds,
    int? orderIndex,
  }) {
    return Alarm(
      id: id ?? this.id,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
