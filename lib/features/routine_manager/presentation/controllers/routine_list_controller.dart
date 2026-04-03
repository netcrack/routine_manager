import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/usecases/get_routines.dart';
import 'active_session_controller.dart';

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

  Future<Result<void, DomainError>> deleteRoutine(String id) async {
    // 1. Read: Check if the routine is currently active (Standard 4.2)
    final activeSession = ref.read(activeSessionControllerProvider);
    if (activeSession.routineId == id && activeSession.status != SessionStatus.inactive) {
      return const Result.failure(DomainError.activeSessionExists);
    }

    // 2. Clear state check: Is there a more formal way? (Fulfills INT-09 lock release indirectly)
    final repository = ref.read(routineRepositoryProvider);
    final result = await repository.deleteRoutine(id);
    
    return result.fold(
      (_) {
        ref.invalidateSelf();
        return const Result.success(null);
      },
      (error) => Result.failure(error),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
