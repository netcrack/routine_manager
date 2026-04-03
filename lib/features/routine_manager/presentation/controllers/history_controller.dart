import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/routine_run.dart';
import '../../domain/usecases/get_run_history.dart';
import '../../domain/usecases/get_run_detail.dart';

part 'history_controller.g.dart';

/// History Controller - Manages the state of past routine executions.
/// // Fulfills INT-16, INT-17
@riverpod
class HistoryController extends _$HistoryController {
  @override
  Future<List<RoutineRun>> build() async {
    final useCase = ref.watch(getRunHistoryUseCaseProvider);
    final result = await useCase.execute();
    
    return result.fold(
      (history) => history,
      (error) => throw Exception('Failed to fetch history: $error'),
    );
  }

  /// Fetch detail for a specific run.
  Future<RoutineRun> getRunDetail(String id) async {
    final useCase = ref.read(getRunDetailUseCaseProvider);
    final result = await useCase.execute(id);
    
    return result.fold(
      (detail) => detail,
      (error) => throw Exception('Failed to fetch run detail: $error'),
    );
  }

  /// Refresh the history list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
