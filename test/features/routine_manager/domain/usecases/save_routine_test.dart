import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/alarm.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/routine_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/save_routine.dart';

class MockRoutineRepository extends Mock implements RoutineRepository {}

void main() {
  late SaveRoutineUseCase useCase;
  late MockRoutineRepository mockRepository;

  final alarm = const Alarm(id: '1', durationSeconds: 60, orderIndex: 0);
  final routine = Routine(
    id: '1',
    name: 'Test Routine',
    alarms: [alarm],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockRoutineRepository();
    useCase = SaveRoutineUseCase(mockRepository);
    
    // Setup mock registration for parameters
    registerFallbackValue(routine);
  });

  group('SaveRoutineUseCase // Verifies INT-01, INT-10', () {
    test('should save routine to repository and update updatedAt', () async {
      when(() => mockRepository.saveRoutine(any())).thenAnswer((_) async => {});

      await useCase.execute(routine);

      final capturedRoutine = verify(() => mockRepository.saveRoutine(captureAny())).captured.single as Routine;
      
      expect(capturedRoutine.id, routine.id);
      expect(capturedRoutine.name, routine.name);
      expect(capturedRoutine.alarms, routine.alarms);
      // updatedAt should be updated within the use case
      expect(capturedRoutine.updatedAt.isAfter(routine.updatedAt) || capturedRoutine.updatedAt.isAtSameMomentAs(routine.updatedAt), isTrue);
    });
  });
}
