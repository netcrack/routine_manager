// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionControllerHash() =>
    r'eccf2254ff51f04e21d153f5f675de8f2b913f84';

/// Active Session Controller - Central state holder for the running routine session.
/// // Fulfills INT-03, INT-05, INT-06, INT-09, INT-11
///
/// Copied from [ActiveSessionController].
@ProviderFor(ActiveSessionController)
final activeSessionControllerProvider =
    NotifierProvider<ActiveSessionController, ActiveSession>.internal(
  ActiveSessionController.new,
  name: r'activeSessionControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSessionController = Notifier<ActiveSession>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
