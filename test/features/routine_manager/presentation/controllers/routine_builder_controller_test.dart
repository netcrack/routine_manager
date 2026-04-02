import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_manager/core/result.dart';
import 'package:routine_manager/features/routine_manager/domain/entities/routine.dart';
import 'package:routine_manager/features/routine_manager/domain/repositories/routine_repository.dart';
import 'package:routine_manager/features/routine_manager/presentation/controllers/routine_builder_controller.dart';

class MockRoutineRepository extends Mock implements RoutineRepository {}

void main() {
  group('RoutineBuilderNotifier // Verifies INT-02, INT-10', () {
    late ProviderContainer container;
    late MockRoutineRepository mockRepository;

    setUp(() {
      mockRepository = MockRoutineRepository();
      container = ProviderContainer(
        overrides: [
          routineRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      registerFallbackValue(
        Routine(
          id: '1',
          name: 'test',
          alarms: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be a new routine with empty alarms', () {
      final state = container.read(routineBuilderProvider());
      expect(state.name, isEmpty);
      expect(state.alarms, isEmpty);
    });

    test('updateName should update the routine name', () {
      final notifier = container.read(routineBuilderProvider().notifier);
      notifier.updateName('Yoga');
      
      final state = container.read(routineBuilderProvider());
      expect(state.name, 'Yoga');
    });

    test('addAlarm should add an alarm to the list', () {
      final notifier = container.read(routineBuilderProvider().notifier);
      notifier.addAlarm(60);
      
      final state = container.read(routineBuilderProvider());
      expect(state.alarms, hasLength(1));
      expect(state.alarms.first.durationSeconds, 60);
      expect(state.alarms.first.orderIndex, 0);
    });

    test('bulkUpdateAlarmDurations should update all alarms in state // Verifies INT-14', () {
      final notifier = container.read(routineBuilderProvider().notifier);
      notifier.addAlarm(60);
      notifier.addAlarm(120);
      
      notifier.bulkUpdateAlarmDurations(300);
      
      final state = container.read(routineBuilderProvider());
      expect(state.alarms.every((a) => a.durationSeconds == 300), isTrue);
    });

    test('reorderAlarms should correctly swap positions', () {
      final notifier = container.read(routineBuilderProvider().notifier);
      notifier.addAlarm(60); // Alarm 0
      notifier.addAlarm(120); // Alarm 1
      
      notifier.reorderAlarms(0, 2); // Move 0 after 1
      
      final state = container.read(routineBuilderProvider());
      expect(state.alarms[0].durationSeconds, 120);
      expect(state.alarms[0].orderIndex, 0);
      expect(state.alarms[1].durationSeconds, 60);
      expect(state.alarms[1].orderIndex, 1);
    });

    test('save should call the save use case and return success', () async {
      when(() => mockRepository.saveRoutine(any()))
          .thenAnswer((_) async => const Result.success(null));

      final notifier = container.read(routineBuilderProvider().notifier);
      notifier.updateName('Morning');
      notifier.addAlarm(60);
      
      final result = await notifier.save();
      
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.saveRoutine(any())).called(1);
    });
  });
}
