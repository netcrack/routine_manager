import 'package:hive/hive.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../../domain/entities/routine_run.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/routine_run_model.dart';

/// History Repository Implementation - Concrete storage using Hive.
/// // Fulfills INT-15, INT-16, INT-18
class HistoryRepositoryImpl implements HistoryRepository {
  static const String boxName = 'routine_history_box';
  final Box<RoutineRunModel> _box;

  HistoryRepositoryImpl(this._box);

  @override
  Future<Result<void, DomainError>> saveRun(RoutineRun run) async {
    try {
      final model = RoutineRunModel.fromEntity(run);
      await _box.put(run.id, model);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<List<RoutineRun>, DomainError>> getHistory() async {
    try {
      // Return history sorted by endTime descending (most recent first)
      final history = _box.values
          .map((e) => e.toEntity())
          .toList()
        ..sort((a, b) => b.endTime.compareTo(a.endTime));
      return Result.success(history);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<RoutineRun, DomainError>> getRunDetail(String id) async {
    try {
      final model = _box.get(id);
      if (model == null) {
        return const Result.failure(DomainError.notFound);
      }
      return Result.success(model.toEntity());
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<void, DomainError>> pruneHistory(Duration maxAge) async {
    try {
      final now = DateTime.now();
      final threshold = now.subtract(maxAge);

      final keysToPrune = _box.keys.where((key) {
        final model = _box.get(key);
        return model != null && model.endTime.isBefore(threshold);
      }).toList();

      await _box.deleteAll(keysToPrune);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }
}
