// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_bus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cityBusApiHash() => r'9a16171dfdb3bb17dcaf260021ce2532bc906bc7';

/// See also [cityBusApi].
@ProviderFor(cityBusApi)
final cityBusApiProvider = AutoDisposeProvider<CityBusApi>.internal(
  cityBusApi,
  name: r'cityBusApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cityBusApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CityBusApiRef = AutoDisposeProviderRef<CityBusApi>;
String _$cityBusRepositoryHash() => r'8520de5181b29b56c6eeba4136e071432e9657ac';

/// See also [cityBusRepository].
@ProviderFor(cityBusRepository)
final cityBusRepositoryProvider =
    AutoDisposeProvider<CityBusRepository>.internal(
      cityBusRepository,
      name: r'cityBusRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$cityBusRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CityBusRepositoryRef = AutoDisposeProviderRef<CityBusRepository>;
String _$cityBusArrivalsHash() => r'f032ac0c766ae476202d28f4a30c0953128a2b6c';

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

/// [stationId] 정류장의 실시간 버스 도착 정보.
/// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
///
/// Copied from [cityBusArrivals].
@ProviderFor(cityBusArrivals)
const cityBusArrivalsProvider = CityBusArrivalsFamily();

/// [stationId] 정류장의 실시간 버스 도착 정보.
/// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
///
/// Copied from [cityBusArrivals].
class CityBusArrivalsFamily extends Family<AsyncValue<List<BusArrival>>> {
  /// [stationId] 정류장의 실시간 버스 도착 정보.
  /// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
  ///
  /// Copied from [cityBusArrivals].
  const CityBusArrivalsFamily();

  /// [stationId] 정류장의 실시간 버스 도착 정보.
  /// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
  ///
  /// Copied from [cityBusArrivals].
  CityBusArrivalsProvider call({required int stationId}) {
    return CityBusArrivalsProvider(stationId: stationId);
  }

  @override
  CityBusArrivalsProvider getProviderOverride(
    covariant CityBusArrivalsProvider provider,
  ) {
    return call(stationId: provider.stationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cityBusArrivalsProvider';
}

/// [stationId] 정류장의 실시간 버스 도착 정보.
/// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
///
/// Copied from [cityBusArrivals].
class CityBusArrivalsProvider
    extends AutoDisposeFutureProvider<List<BusArrival>> {
  /// [stationId] 정류장의 실시간 버스 도착 정보.
  /// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
  ///
  /// Copied from [cityBusArrivals].
  CityBusArrivalsProvider({required int stationId})
    : this._internal(
        (ref) =>
            cityBusArrivals(ref as CityBusArrivalsRef, stationId: stationId),
        from: cityBusArrivalsProvider,
        name: r'cityBusArrivalsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$cityBusArrivalsHash,
        dependencies: CityBusArrivalsFamily._dependencies,
        allTransitiveDependencies:
            CityBusArrivalsFamily._allTransitiveDependencies,
        stationId: stationId,
      );

  CityBusArrivalsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stationId,
  }) : super.internal();

  final int stationId;

  @override
  Override overrideWith(
    FutureOr<List<BusArrival>> Function(CityBusArrivalsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CityBusArrivalsProvider._internal(
        (ref) => create(ref as CityBusArrivalsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stationId: stationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BusArrival>> createElement() {
    return _CityBusArrivalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CityBusArrivalsProvider && other.stationId == stationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CityBusArrivalsRef on AutoDisposeFutureProviderRef<List<BusArrival>> {
  /// The parameter `stationId` of this provider.
  int get stationId;
}

class _CityBusArrivalsProviderElement
    extends AutoDisposeFutureProviderElement<List<BusArrival>>
    with CityBusArrivalsRef {
  _CityBusArrivalsProviderElement(super.provider);

  @override
  int get stationId => (origin as CityBusArrivalsProvider).stationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
