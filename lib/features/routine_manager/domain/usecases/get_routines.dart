import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

part 'get_routines.g.dart';

/// Get Routines Use Case - Pure Dart logic to retrieve all routines.
/// // Fulfills INT-01
class GetRoutinesUseCase {
  final RoutineRepository repository;

  GetRoutinesUseCase(this.repository);

  Future<List<Routine>> execute() async {
    return await repository.getAllRoutines();
  }
}

@riverpod
GetRoutinesUseCase getRoutinesUseCase(GetRoutinesUseCaseRef ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return GetRoutinesUseCase(repository);
}
