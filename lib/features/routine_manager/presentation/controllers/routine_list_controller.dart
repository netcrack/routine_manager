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
  Future<List<Routine>> build() {
    final useCase = ref.watch(getRoutinesUseCaseProvider);
    return useCase.execute();
  }

  Future<void> deleteRoutine(String id) async {
    final repository = ref.read(routineRepositoryProvider);
    await repository.deleteRoutine(id);
    // Refresh the list after deletion
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
