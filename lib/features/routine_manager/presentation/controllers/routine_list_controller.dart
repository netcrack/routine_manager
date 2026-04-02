import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/usecases/get_routines.dart';

part 'routine_list_controller.g.dart';

/// Routine List Controller - Manages the list of routines state.
/// // Fulfills INT-01
@riverpod
class RoutineList extends _$RoutineList {
  @override
  Future<List<Routine>> build() async {
    final useCase = ref.watch(getRoutinesUseCaseProvider);
    final result = await useCase.execute();
    return result.fold(
      (routines) => routines,
      (error) => throw Exception('Failed to fetch routines: $error'),
    );
  }

  Future<void> deleteRoutine(String id) async {
    final repository = ref.read(routineRepositoryProvider);
    final result = await repository.deleteRoutine(id);
    
    result.when(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (error) => throw Exception('Failed to delete routine: $error'),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
