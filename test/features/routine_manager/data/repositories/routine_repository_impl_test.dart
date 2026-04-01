import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/features/routine_manager/data/models/routine_model.dart';
import 'package:routine_manager/features/routine_manager/data/repositories/routine_repository_impl.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';

class MockBox extends Mock implements Box<RoutineModel> {}

void main() {
  late RoutineRepositoryImpl repository;
  late MockBox mockBox;

  final alarm = const Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
  final routine = Routine(
    id: '1',
    name: 'Yoga',
    alarms: [alarm],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockBox = MockBox();
    repository = RoutineRepositoryImpl(mockBox);
    registerFallbackValue(RoutineModel.fromEntity(routine));
  });

  group('RoutineRepositoryImpl // Verifies INT-01, INT-10', () {
    test('should save routine to box', () async {
      when(() => mockBox.put(any<String>(), any())).thenAnswer((_) async => {});

      await repository.saveRoutine(routine);

      verify(() => mockBox.put(routine.id, any())).called(1);
    });

    test('should get routine from box and convert to entity', () async {
      final model = RoutineModel.fromEntity(routine);
      when(() => mockBox.get(any())).thenReturn(model);

      final result = await repository.getRoutine(routine.id);

      expect(result, equals(routine));
      verify(() => mockBox.get(routine.id)).called(1);
    });

    test('should return null when routine not found', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.getRoutine('non-existent');

      expect(result, isNull);
    });

    test('should get all routines from box', () async {
      final model = RoutineModel.fromEntity(routine);
      when(() => mockBox.values).thenReturn([model]);

      final results = await repository.getAllRoutines();

      expect(results, hasLength(1));
      expect(results.first, equals(routine));
    });

    test('should delete routine from box', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async => {});

      await repository.deleteRoutine(routine.id);

      verify(() => mockBox.delete(routine.id)).called(1);
    });
  });
}
