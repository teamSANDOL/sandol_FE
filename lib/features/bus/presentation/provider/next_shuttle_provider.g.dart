// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_shuttle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nextShuttleHash() => r'd08f445c3793190b139b91f44a89ceee4d70687d';

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

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
@ProviderFor(nextShuttle)
const nextShuttleProvider = NextShuttleFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
class NextShuttleFamily extends Family<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// Copied from [nextShuttle].
  const NextShuttleFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// Copied from [nextShuttle].
  NextShuttleProvider call({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) {
    return NextShuttleProvider(route: route, direction: direction);
  }

  @override
  NextShuttleProvider getProviderOverride(
    covariant NextShuttleProvider provider,
  ) {
    return call(route: provider.route, direction: provider.direction);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'nextShuttleProvider';
}

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
class NextShuttleProvider extends AutoDisposeProvider<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// Copied from [nextShuttle].
  NextShuttleProvider({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) : this._internal(
         (ref) => nextShuttle(
           ref as NextShuttleRef,
           route: route,
           direction: direction,
         ),
         from: nextShuttleProvider,
         name: r'nextShuttleProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$nextShuttleHash,
         dependencies: NextShuttleFamily._dependencies,
         allTransitiveDependencies:
             NextShuttleFamily._allTransitiveDependencies,
         route: route,
         direction: direction,
       );

  NextShuttleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.route,
    required this.direction,
  }) : super.internal();

  final ShuttleRoute route;
  final ShuttleDirection direction;

  @override
  Override overrideWith(NextShuttle Function(NextShuttleRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: NextShuttleProvider._internal(
        (ref) => create(ref as NextShuttleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        route: route,
        direction: direction,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<NextShuttle> createElement() {
    return _NextShuttleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NextShuttleProvider &&
        other.route == route &&
        other.direction == direction;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, route.hashCode);
    hash = _SystemHash.combine(hash, direction.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NextShuttleRef on AutoDisposeProviderRef<NextShuttle> {
  /// The parameter `route` of this provider.
  ShuttleRoute get route;

  /// The parameter `direction` of this provider.
  ShuttleDirection get direction;
}

class _NextShuttleProviderElement
    extends AutoDisposeProviderElement<NextShuttle>
    with NextShuttleRef {
  _NextShuttleProviderElement(super.provider);

  @override
  ShuttleRoute get route => (origin as NextShuttleProvider).route;
  @override
  ShuttleDirection get direction => (origin as NextShuttleProvider).direction;
}

String _$shuttleClockHash() => r'e60ba28449fdecb114b97624e5448a1563dce271';

/// 셔틀 계산의 기준 시각(= 마지막 새로고침 시각).
///
/// 홈·버스 상세 화면이 공유하며, [ShuttleClock.refresh]를 호출하면
/// 이 값을 watch하는 [nextShuttleProvider]가 모두 재계산된다.
///
/// Copied from [ShuttleClock].
@ProviderFor(ShuttleClock)
final shuttleClockProvider = NotifierProvider<ShuttleClock, DateTime>.internal(
  ShuttleClock.new,
  name: r'shuttleClockProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$shuttleClockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ShuttleClock = Notifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
