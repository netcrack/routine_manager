import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/routine_run.dart';

/// History Repository Interface - Pure Dart definition for routine run history persistence.
/// // Fulfills INT-15, INT-16, INT-18
abstract class HistoryRepository {
  /// Save a new routine run execution.
  Future<Result<void, DomainError>> saveRun(RoutineRun run);

  /// Get all routine run executions, chronologically sorted.
  Future<Result<List<RoutineRun>, DomainError>> getHistory();

  /// Get detailed metadata for a specific routine run.
  Future<Result<RoutineRun, DomainError>> getRunDetail(String id);

  /// Prune history records older than the specified duration.
  /// // Satisfies INT-18 (6-Month Sliding Window)
  Future<Result<void, DomainError>> pruneHistory(Duration maxAge);
}
