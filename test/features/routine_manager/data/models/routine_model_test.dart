import 'package:flutter_test/flutter_test.dart';
import 'package:routine_manager/features/routine_manager/data/models/alarm_model.dart';
import 'package:routine_manager/features/routine_manager/data/models/routine_model.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';

void main() {
  group('RoutineModel Mapping // Verifies INT-01, INT-04, INT-10', () {
    final alarmEntity = const Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
    final now = DateTime.now();
    final routineEntity = Routine(
      id: '1',
      name: 'Yoga',
      alarms: [alarmEntity],
      createdAt: now,
      updatedAt: now,
    );

    test('should map from entity to model', () {
      final model = RoutineModel.fromEntity(routineEntity);
      
      expect(model.id, routineEntity.id);
      expect(model.name, routineEntity.name);
      expect(model.alarms, hasLength(1));
      expect(model.alarms.first.id, alarmEntity.id);
      expect(model.createdAt, routineEntity.createdAt);
    });

    test('should map from model to entity', () {
      final model = RoutineModel(
        id: '1',
        name: 'Yoga',
        alarms: [
          AlarmModel(id: '1', durationSeconds: 60, orderIndex: 0)
        ],
        createdAt: now,
        updatedAt: now,
      );
      
      final entity = model.toEntity();
      
      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity.alarms, hasLength(1));
      expect(entity.alarms.first.id, '1');
      expect(entity.createdAt, model.createdAt);
    });
  });
}
