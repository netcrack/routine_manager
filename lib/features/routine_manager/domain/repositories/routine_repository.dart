import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/routine.dart';

part 'routine_repository.g.dart';

/// Routine Repository Interface - Pure Dart definition for routine persistence.
/// // Fulfills INT-01, INT-10
abstract class RoutineRepository {
  Future<void> saveRoutine(Routine routine);
  Future<Routine?> getRoutine(String id);
  Future<List<Routine>> getAllRoutines();
  Future<void> deleteRoutine(String id);
}

@riverpod
RoutineRepository routineRepository(RoutineRepositoryRef ref) {
  throw UnimplementedError('RoutineRepository must be provided');
}
