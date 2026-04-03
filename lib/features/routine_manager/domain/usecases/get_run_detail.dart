import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/routine_run.dart';
import '../repositories/history_repository.dart';

part 'get_run_detail.g.dart';

/// Get Run Detail Use Case - Pure Dart logic to retrieve metadata for a single routine execution.
/// // Fulfills INT-17
class GetRunDetailUseCase {
  final HistoryRepository repository;

  GetRunDetailUseCase(this.repository);

  Future<Result<RoutineRun, DomainError>> execute(String id) async {
    return await repository.getRunDetail(id);
  }
}

@riverpod
GetRunDetailUseCase getRunDetailUseCase(GetRunDetailUseCaseRef ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return GetRunDetailUseCase(repository);
}
