import 'package:hive/hive.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../models/routine_model.dart';

/// Routine Repository Implementation - Concrete storage using Hive.
/// // Fulfills INT-01, INT-10
class RoutineRepositoryImpl implements RoutineRepository {
  static const String boxName = 'routines_box';
  final Box<RoutineModel> _box;

  RoutineRepositoryImpl(this._box);

  @override
  Future<void> saveRoutine(Routine routine) async {
    final model = RoutineModel.fromEntity(routine);
    await _box.put(routine.id, model);
  }

  @override
  Future<Routine?> getRoutine(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<List<Routine>> getAllRoutines() async {
    return _box.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _box.delete(id);
  }
}
// Note: routineRepositoryProvider is now defined in routine_repository.dart
