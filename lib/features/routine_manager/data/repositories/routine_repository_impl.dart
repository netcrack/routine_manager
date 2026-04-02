import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../models/routine_model.dart';
import 'package:hive/hive.dart';

/// Routine Repository Implementation - Concrete storage using Hive.
/// // Fulfills INT-01, INT-10
class RoutineRepositoryImpl implements RoutineRepository {
  static const String boxName = 'routines_box';
  final Box<RoutineModel> _box;

  RoutineRepositoryImpl(this._box);

  @override
  Future<Result<void, DomainError>> saveRoutine(Routine routine) async {
    try {
      final model = RoutineModel.fromEntity(routine);
      await _box.put(routine.id, model);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<Routine, DomainError>> getRoutine(String id) async {
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
  Future<Result<List<Routine>, DomainError>> getAllRoutines() async {
    try {
      final routines = _box.values.map((e) => e.toEntity()).toList();
      return Result.success(routines);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<void, DomainError>> deleteRoutine(String id) async {
    try {
      await _box.delete(id);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }
}
