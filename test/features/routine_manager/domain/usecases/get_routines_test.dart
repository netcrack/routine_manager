import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/routine_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/get_routines.dart';

class MockRoutineRepository extends Mock implements RoutineRepository {}

void main() {
  late GetRoutinesUseCase useCase;
  late MockRoutineRepository mockRepository;

  final alarm = const Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
  final routine1 = Routine(
    id: '1',
    name: 'Yoga',
    alarms: [alarm],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final routine2 = Routine(
    id: '2',
    name: 'Hiit',
    alarms: [alarm],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockRoutineRepository();
    useCase = GetRoutinesUseCase(mockRepository);
  });

  group('GetRoutinesUseCase // Verifies INT-01', () {
    test('should get all routines from repository', () async {
      when(() => mockRepository.getAllRoutines()).thenAnswer((_) async => [routine1, routine2]);

      final results = await useCase.execute();

      expect(results, hasLength(2));
      expect(results[0].id, routine1.id);
      expect(results[1].id, routine2.id);
      verify(() => mockRepository.getAllRoutines()).called(1);
    });
  });
}
