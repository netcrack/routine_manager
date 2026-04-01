import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/routine.dart';
import '../../domain/usecases/save_routine.dart';
import 'routine_list_controller.dart';

part 'routine_builder_controller.g.dart';

/// Routine Builder Controller - Manages the transient state of a routine being created or edited.
/// // Fulfills INT-01, INT-02, INT-04, INT-10
@riverpod
class RoutineBuilder extends _$RoutineBuilder {
  @override
  Routine build({Routine? initialRoutine}) {
    if (initialRoutine != null) {
      return initialRoutine;
    }
    
    // Default initial state for a new routine
    return Routine(
      id: const Uuid().v4(),
      name: '',
      alarms: const [], // Will be validated before saving
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void addAlarm(int durationSeconds) {
    final newAlarm = Alarm(
      id: const Uuid().v4(),
      durationSeconds: durationSeconds,
      orderIndex: state.alarms.length,
    );
    
    state = state.copyWith(alarms: [...state.alarms, newAlarm]);
  }

  void removeAlarm(String id) {
    final updatedAlarms = state.alarms.where((a) => a.id != id).toList();
    // Update orderIndex
    for (int i = 0; i < updatedAlarms.length; i++) {
      updatedAlarms[i] = updatedAlarms[i].copyWith(orderIndex: i);
    }
    state = state.copyWith(alarms: updatedAlarms);
  }

  void reorderAlarms(int oldIndex, int newIndex) {
    var alarms = List<Alarm>.from(state.alarms);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Alarm item = alarms.removeAt(oldIndex);
    alarms.insert(newIndex, item);
    
    // Update orderIndex
    for (int i = 0; i < alarms.length; i++) {
      alarms[i] = alarms[i].copyWith(orderIndex: i);
    }
    
    state = state.copyWith(alarms: alarms);
  }

  Future<void> save() async {
    final saveUseCase = ref.read(saveRoutineUseCaseProvider);
    await saveUseCase.execute(state);
    
    // Invalidate the routine list to refresh it
    ref.invalidate(routineListProvider);
  }
}
