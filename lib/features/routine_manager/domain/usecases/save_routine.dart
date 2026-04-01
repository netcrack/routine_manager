import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

part 'save_routine.g.dart';

/// Save Routine Use Case - Pure Dart logic to save or update a routine.
/// // Fulfills INT-01, INT-10
class SaveRoutineUseCase {
  final RoutineRepository repository;

  SaveRoutineUseCase(this.repository);

  Future<void> execute(Routine routine) async {
    // Business rule: Routines must have at least one alarm (Fulfills INT-01)
    if (routine.alarms.isEmpty) {
      throw ArgumentError('A routine must have at least one alarm.');
    }
    
    // Update the routine's updatedAt timestamp
    final updatedRoutine = routine.copyWith(updatedAt: DateTime.now());
    
    await repository.saveRoutine(updatedRoutine);
  }
}

@riverpod
SaveRoutineUseCase saveRoutineUseCase(SaveRoutineUseCaseRef ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return SaveRoutineUseCase(repository);
}
