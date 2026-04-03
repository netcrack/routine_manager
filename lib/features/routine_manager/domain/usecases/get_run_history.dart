import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/routine_run.dart';
import '../repositories/history_repository.dart';

part 'get_run_history.g.dart';

/// Get Run History Use Case - Pure Dart logic to retrieve sorted execution history.
/// // Fulfills INT-16
class GetRunHistoryUseCase {
  final HistoryRepository repository;

  GetRunHistoryUseCase(this.repository);

  Future<Result<List<RoutineRun>, DomainError>> execute() async {
    return await repository.getHistory();
  }
}

@riverpod
GetRunHistoryUseCase getRunHistoryUseCase(GetRunHistoryUseCaseRef ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return GetRunHistoryUseCase(repository);
}
