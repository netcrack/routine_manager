import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

part 'save_routine.g.dart';

/// Save Routine Use Case - Pure Dart logic to save or update a routine.
/// // Fulfills INT-01, INT-10
class SaveRoutineUseCase {
  final RoutineRepository repository;

  SaveRoutineUseCase(this.repository);

  Future<Result<void, DomainError>> execute(Routine routine) async {
    // Business rule: Routines must have at least one alarm (Fulfills INT-01)
    if (routine.alarms.isEmpty) {
      return const Result.failure(DomainError.invalidRoutine);
    }
    
    // Update the routine's updatedAt timestamp
    final updatedRoutine = routine.copyWith(updatedAt: DateTime.now());
    
    return await repository.saveRoutine(updatedRoutine);
  }
}

@riverpod
SaveRoutineUseCase saveRoutineUseCase(SaveRoutineUseCaseRef ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return SaveRoutineUseCase(repository);
}
