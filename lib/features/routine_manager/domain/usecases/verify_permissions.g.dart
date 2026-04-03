// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_permissions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$verifyPermissionsHash() => r'f7511438578b45bfe3799b56a170d9c312afd3a5';

/// Verify Permissions UseCase - Checks if the app has required OS permissions to run routines.
/// // Fulfills INT-09, Standard 3.1
///
/// Copied from [verifyPermissions].
@ProviderFor(verifyPermissions)
final verifyPermissionsProvider =
    AutoDisposeFutureProvider<Result<bool, DomainError>>.internal(
  verifyPermissions,
  name: r'verifyPermissionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$verifyPermissionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VerifyPermissionsRef
    = AutoDisposeFutureProviderRef<Result<bool, DomainError>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
