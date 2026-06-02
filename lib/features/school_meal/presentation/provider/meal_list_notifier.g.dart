// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mealApiHash() => r'b16eb0086700ece3e9b4c8a57fdb78cc01938c91';

/// See also [mealApi].
@ProviderFor(mealApi)
final mealApiProvider = AutoDisposeProvider<MealApi>.internal(
  mealApi,
  name: r'mealApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mealApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealApiRef = AutoDisposeProviderRef<MealApi>;
String _$mealRepositoryHash() => r'2f7f12068ca6d3962bf6f9373e66c869d3e7af90';

/// See also [mealRepository].
@ProviderFor(mealRepository)
final mealRepositoryProvider = AutoDisposeProvider<MealRepository>.internal(
  mealRepository,
  name: r'mealRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mealRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealRepositoryRef = AutoDisposeProviderRef<MealRepository>;
String _$mealListNotifierHash() => r'979a3d7405a2e5816c87f7ea0d7bbea1788cb088';

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

abstract class _$MealListNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Meal>> {
  late final String? date;

  FutureOr<List<Meal>> build({String? date});
}

/// See also [MealListNotifier].
@ProviderFor(MealListNotifier)
const mealListNotifierProvider = MealListNotifierFamily();

/// See also [MealListNotifier].
class MealListNotifierFamily extends Family<AsyncValue<List<Meal>>> {
  /// See also [MealListNotifier].
  const MealListNotifierFamily();

  /// See also [MealListNotifier].
  MealListNotifierProvider call({String? date}) {
    return MealListNotifierProvider(date: date);
  }

  @override
  MealListNotifierProvider getProviderOverride(
    covariant MealListNotifierProvider provider,
  ) {
    return call(date: provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'mealListNotifierProvider';
}

/// See also [MealListNotifier].
class MealListNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<MealListNotifier, List<Meal>> {
  /// See also [MealListNotifier].
  MealListNotifierProvider({String? date})
    : this._internal(
        () => MealListNotifier()..date = date,
        from: mealListNotifierProvider,
        name: r'mealListNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$mealListNotifierHash,
        dependencies: MealListNotifierFamily._dependencies,
        allTransitiveDependencies:
            MealListNotifierFamily._allTransitiveDependencies,
        date: date,
      );

  MealListNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final String? date;

  @override
  FutureOr<List<Meal>> runNotifierBuild(covariant MealListNotifier notifier) {
    return notifier.build(date: date);
  }

  @override
  Override overrideWith(MealListNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MealListNotifierProvider._internal(
        () => create()..date = date,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MealListNotifier, List<Meal>>
  createElement() {
    return _MealListNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MealListNotifierProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MealListNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Meal>> {
  /// The parameter `date` of this provider.
  String? get date;
}

class _MealListNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<MealListNotifier, List<Meal>>
    with MealListNotifierRef {
  _MealListNotifierProviderElement(super.provider);

  @override
  String? get date => (origin as MealListNotifierProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
