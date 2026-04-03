import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/domain_error.dart';
import 'package:routine_manager/core/result.dart';
import 'package:routine_manager/features/routine_manager/presentation/controllers/routine_list_controller.dart';
import 'package:routine_manager/features/routine_manager/presentation/controllers/active_session_controller.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/active_session.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/routine_repository.dart';
import 'package:routine_manager/features/routine_manager/domain/usecases/get_routines.dart';

class MockRoutineRepository extends Mock implements RoutineRepository {}
class MockGetRoutinesUseCase extends Mock implements GetRoutinesUseCase {}

class FakeActiveSessionController extends ActiveSessionController {
  final ActiveSession _initialState;
  FakeActiveSessionController(this._initialState);

  @override
  ActiveSession build() => _initialState;
}

void main() {
  late MockRoutineRepository mockRepo;
  late MockGetRoutinesUseCase mockGetUseCase;
  
  setUp(() {
    mockRepo = MockRoutineRepository();
    mockGetUseCase = MockGetRoutinesUseCase();
    
    // Default mock behavior
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => const Result.success([]));
  });

  ProviderContainer makeContainer({ActiveSession? session}) {
    final container = ProviderContainer(
      overrides: [
        routineRepositoryProvider.overrideWithValue(mockRepo),
        getRoutinesUseCaseProvider.overrideWithValue(mockGetUseCase),
        if (session != null) 
          activeSessionControllerProvider.overrideWith(() => FakeActiveSessionController(session)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('RoutineListController Delete Guard (Journey 3)', () {
    test('should delete routine if it is NOT active', () async {
      final container = makeContainer(session: const ActiveSession());
      when(() => mockRepo.deleteRoutine('1')).thenAnswer((_) async => const Result.success(null));

      final result = await container.read(routineListProvider.notifier).deleteRoutine('1');

      expect(result.isSuccess, true);
      verify(() => mockRepo.deleteRoutine('1')).called(1);
    });

    test('should PREVENT deletion if routine is currently active', () async {
      final activeSession = const ActiveSession(
        routineId: '1',
        status: SessionStatus.running,
      );
      final container = makeContainer(session: activeSession);

      final result = await container.read(routineListProvider.notifier).deleteRoutine('1');

      expect(result.isFailure, true);
      expect(result.failure, DomainError.activeSessionExists);
      verifyNever(() => mockRepo.deleteRoutine('1'));
    });

    test('should propagate storage failure from repository', () async {
      final container = makeContainer(session: const ActiveSession());
      when(() => mockRepo.deleteRoutine('1')).thenAnswer(
        (_) async => const Result.failure(DomainError.storageFailure)
      );

      final result = await container.read(routineListProvider.notifier).deleteRoutine('1');

      expect(result.isFailure, true);
      expect(result.failure, DomainError.storageFailure);
    });
  });
}
