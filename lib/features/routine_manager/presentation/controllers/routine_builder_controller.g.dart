// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_builder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routineBuilderHash() => r'dff1873e8c74aec3563370c3a9d48cd20df02fee';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$RoutineBuilder extends BuildlessAutoDisposeNotifier<Routine> {
  late final Routine? initialRoutine;

  Routine build({
    Routine? initialRoutine,
  });
}

/// Routine Builder Controller - Manages the transient state of a routine being created or edited.
/// // Fulfills INT-01, INT-02, INT-04, INT-10
///
/// Copied from [RoutineBuilder].
@ProviderFor(RoutineBuilder)
const routineBuilderProvider = RoutineBuilderFamily();

/// Routine Builder Controller - Manages the transient state of a routine being created or edited.
/// // Fulfills INT-01, INT-02, INT-04, INT-10
///
/// Copied from [RoutineBuilder].
class RoutineBuilderFamily extends Family<Routine> {
  /// Routine Builder Controller - Manages the transient state of a routine being created or edited.
  /// // Fulfills INT-01, INT-02, INT-04, INT-10
  ///
  /// Copied from [RoutineBuilder].
  const RoutineBuilderFamily();

  /// Routine Builder Controller - Manages the transient state of a routine being created or edited.
  /// // Fulfills INT-01, INT-02, INT-04, INT-10
  ///
  /// Copied from [RoutineBuilder].
  RoutineBuilderProvider call({
    Routine? initialRoutine,
  }) {
    return RoutineBuilderProvider(
      initialRoutine: initialRoutine,
    );
  }

  @override
  RoutineBuilderProvider getProviderOverride(
    covariant RoutineBuilderProvider provider,
  ) {
    return call(
      initialRoutine: provider.initialRoutine,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'routineBuilderProvider';
}

/// Routine Builder Controller - Manages the transient state of a routine being created or edited.
/// // Fulfills INT-01, INT-02, INT-04, INT-10
///
/// Copied from [RoutineBuilder].
class RoutineBuilderProvider
    extends AutoDisposeNotifierProviderImpl<RoutineBuilder, Routine> {
  /// Routine Builder Controller - Manages the transient state of a routine being created or edited.
  /// // Fulfills INT-01, INT-02, INT-04, INT-10
  ///
  /// Copied from [RoutineBuilder].
  RoutineBuilderProvider({
    Routine? initialRoutine,
  }) : this._internal(
          () => RoutineBuilder()..initialRoutine = initialRoutine,
          from: routineBuilderProvider,
          name: r'routineBuilderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$routineBuilderHash,
          dependencies: RoutineBuilderFamily._dependencies,
          allTransitiveDependencies:
              RoutineBuilderFamily._allTransitiveDependencies,
          initialRoutine: initialRoutine,
        );

  RoutineBuilderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialRoutine,
  }) : super.internal();

  final Routine? initialRoutine;

  @override
  Routine runNotifierBuild(
    covariant RoutineBuilder notifier,
  ) {
    return notifier.build(
      initialRoutine: initialRoutine,
    );
  }

  @override
  Override overrideWith(RoutineBuilder Function() create) {
    return ProviderOverride(
      origin: this,
      override: RoutineBuilderProvider._internal(
        () => create()..initialRoutine = initialRoutine,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialRoutine: initialRoutine,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<RoutineBuilder, Routine> createElement() {
    return _RoutineBuilderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoutineBuilderProvider &&
        other.initialRoutine == initialRoutine;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialRoutine.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RoutineBuilderRef on AutoDisposeNotifierProviderRef<Routine> {
  /// The parameter `initialRoutine` of this provider.
  Routine? get initialRoutine;
}

class _RoutineBuilderProviderElement
    extends AutoDisposeNotifierProviderElement<RoutineBuilder, Routine>
    with RoutineBuilderRef {
  _RoutineBuilderProviderElement(super.provider);

  @override
  Routine? get initialRoutine =>
      (origin as RoutineBuilderProvider).initialRoutine;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
