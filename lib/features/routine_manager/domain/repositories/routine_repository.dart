import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/routine.dart';

part 'routine_repository.g.dart';

/// Routine Repository Interface - Pure Dart definition for routine persistence.
/// // Fulfills INT-01, INT-10
abstract class RoutineRepository {
  Future<Result<void, DomainError>> saveRoutine(Routine routine);
  Future<Result<Routine, DomainError>> getRoutine(String id);
  Future<Result<List<Routine>, DomainError>> getAllRoutines();
  Future<Result<void, DomainError>> deleteRoutine(String id);
}

@riverpod
RoutineRepository routineRepository(RoutineRepositoryRef ref) {
  throw UnimplementedError('RoutineRepository must be provided');
}
