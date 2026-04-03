// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyControllerHash() => r'4a16615b813ce56d16521fce28d9da2afe148135';

/// History Controller - Manages the state of past routine executions.
/// // Fulfills INT-16, INT-17
///
/// Copied from [HistoryController].
@ProviderFor(HistoryController)
final historyControllerProvider = AutoDisposeAsyncNotifierProvider<
    HistoryController, List<RoutineRun>>.internal(
  HistoryController.new,
  name: r'historyControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HistoryController = AutoDisposeAsyncNotifier<List<RoutineRun>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
