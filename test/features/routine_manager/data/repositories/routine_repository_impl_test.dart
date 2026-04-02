import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/domain_error.dart';
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
    test('should save routine to box and return success', () async {
      when(() => mockBox.put(any<String>(), any())).thenAnswer((_) async => {});

      final result = await repository.saveRoutine(routine);

      expect(result.isSuccess, isTrue);
      verify(() => mockBox.put(routine.id, any())).called(1);
    });

    test('should return storageFailure when put fails', () async {
      when(() => mockBox.put(any<String>(), any())).thenThrow(Exception());

      final result = await repository.saveRoutine(routine);

      expect(result.isFailure, isTrue);
      expect(result.failure, DomainError.storageFailure);
    });

    test('should get routine from box and convert to entity', () async {
      final model = RoutineModel.fromEntity(routine);
      when(() => mockBox.get(any())).thenReturn(model);

      final result = await repository.getRoutine(routine.id);

      expect(result.isSuccess, isTrue);
      expect(result.success, equals(routine));
      verify(() => mockBox.get(routine.id)).called(1);
    });

    test('should return notFound when routine not found', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.getRoutine('non-existent');

      expect(result.isFailure, isTrue);
      expect(result.failure, DomainError.notFound);
    });

    test('should get all routines from box', () async {
      final model = RoutineModel.fromEntity(routine);
      when(() => mockBox.values).thenReturn([model]);

      final result = await repository.getAllRoutines();

      expect(result.isSuccess, isTrue);
      expect(result.success, hasLength(1));
      expect(result.success.first, equals(routine));
    });

    test('should delete routine from box', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async => {});

      final result = await repository.deleteRoutine(routine.id);

      expect(result.isSuccess, isTrue);
      verify(() => mockBox.delete(routine.id)).called(1);
    });
  });
}
