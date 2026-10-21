// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_shuttle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shuttleStopsHash() => r'8a75f96c9fae33e628e0c8652e845037fe0ddbf6';

/// 서버 정류장 id → 정류장. 서버 것이 있으면 그것을, 없으면 내장 상수를 쓴다.
///
/// Copied from [shuttleStops].
@ProviderFor(shuttleStops)
final shuttleStopsProvider =
    AutoDisposeProvider<Map<String, ShuttleStop>>.internal(
      shuttleStops,
      name: r'shuttleStopsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$shuttleStopsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShuttleStopsRef = AutoDisposeProviderRef<Map<String, ShuttleStop>>;
String _$shuttleTimetableHash() => r'af2a6dda1e829d5f420e13af1b672f4699665143';

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

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
/// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
///
/// Copied from [shuttleTimetable].
@ProviderFor(shuttleTimetable)
const shuttleTimetableProvider = ShuttleTimetableFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
/// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
///
/// Copied from [shuttleTimetable].
class ShuttleTimetableFamily extends Family<ShuttleTimetable?> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
  /// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
  ///
  /// Copied from [shuttleTimetable].
  const ShuttleTimetableFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
  /// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
  ///
  /// Copied from [shuttleTimetable].
  ShuttleTimetableProvider call({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) {
    return ShuttleTimetableProvider(route: route, direction: direction);
  }

  @override
  ShuttleTimetableProvider getProviderOverride(
    covariant ShuttleTimetableProvider provider,
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
  String? get name => r'shuttleTimetableProvider';
}

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
/// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
///
/// Copied from [shuttleTimetable].
class ShuttleTimetableProvider extends AutoDisposeProvider<ShuttleTimetable?> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
  /// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
  ///
  /// Copied from [shuttleTimetable].
  ShuttleTimetableProvider({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) : this._internal(
         (ref) => shuttleTimetable(
           ref as ShuttleTimetableRef,
           route: route,
           direction: direction,
         ),
         from: shuttleTimetableProvider,
         name: r'shuttleTimetableProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$shuttleTimetableHash,
         dependencies: ShuttleTimetableFamily._dependencies,
         allTransitiveDependencies:
             ShuttleTimetableFamily._allTransitiveDependencies,
         route: route,
         direction: direction,
       );

  ShuttleTimetableProvider._internal(
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
  Override overrideWith(
    ShuttleTimetable? Function(ShuttleTimetableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShuttleTimetableProvider._internal(
        (ref) => create(ref as ShuttleTimetableRef),
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
  AutoDisposeProviderElement<ShuttleTimetable?> createElement() {
    return _ShuttleTimetableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShuttleTimetableProvider &&
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
mixin ShuttleTimetableRef on AutoDisposeProviderRef<ShuttleTimetable?> {
  /// The parameter `route` of this provider.
  ShuttleRoute get route;

  /// The parameter `direction` of this provider.
  ShuttleDirection get direction;
}

class _ShuttleTimetableProviderElement
    extends AutoDisposeProviderElement<ShuttleTimetable?>
    with ShuttleTimetableRef {
  _ShuttleTimetableProviderElement(super.provider);

  @override
  ShuttleRoute get route => (origin as ShuttleTimetableProvider).route;
  @override
  ShuttleDirection get direction =>
      (origin as ShuttleTimetableProvider).direction;
}

String _$nextShuttleHash() => r'10da65dbdbd8f2935ff7320f6941f6726c0fc319';

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
/// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
///
/// Copied from [nextShuttle].
@ProviderFor(nextShuttle)
const nextShuttleProvider = NextShuttleFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
/// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
///
/// Copied from [nextShuttle].
class NextShuttleFamily extends Family<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
  /// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
  ///
  /// Copied from [nextShuttle].
  const NextShuttleFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
  /// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
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
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
/// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
///
/// Copied from [nextShuttle].
class NextShuttleProvider extends AutoDisposeProvider<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// 정왕역 ↔ 제2캠퍼스는 직행이 남아 있지 않아도 본교 환승 연결이 있으면
  /// "운행 종료"·"운행 안함" 대신 가장 빠른 환승편을 안내한다.
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

String _$upcomingShuttlesHash() => r'8423d478688aaa6e70aa80d76fa529cffe25f4e1';

/// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
///
/// Copied from [upcomingShuttles].
@ProviderFor(upcomingShuttles)
const upcomingShuttlesProvider = UpcomingShuttlesFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
///
/// Copied from [upcomingShuttles].
class UpcomingShuttlesFamily extends Family<List<ShuttleEntry>> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
  ///
  /// Copied from [upcomingShuttles].
  const UpcomingShuttlesFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
  ///
  /// Copied from [upcomingShuttles].
  UpcomingShuttlesProvider call({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) {
    return UpcomingShuttlesProvider(route: route, direction: direction);
  }

  @override
  UpcomingShuttlesProvider getProviderOverride(
    covariant UpcomingShuttlesProvider provider,
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
  String? get name => r'upcomingShuttlesProvider';
}

/// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
///
/// Copied from [upcomingShuttles].
class UpcomingShuttlesProvider extends AutoDisposeProvider<List<ShuttleEntry>> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
  ///
  /// Copied from [upcomingShuttles].
  UpcomingShuttlesProvider({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) : this._internal(
         (ref) => upcomingShuttles(
           ref as UpcomingShuttlesRef,
           route: route,
           direction: direction,
         ),
         from: upcomingShuttlesProvider,
         name: r'upcomingShuttlesProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$upcomingShuttlesHash,
         dependencies: UpcomingShuttlesFamily._dependencies,
         allTransitiveDependencies:
             UpcomingShuttlesFamily._allTransitiveDependencies,
         route: route,
         direction: direction,
       );

  UpcomingShuttlesProvider._internal(
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
  Override overrideWith(
    List<ShuttleEntry> Function(UpcomingShuttlesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingShuttlesProvider._internal(
        (ref) => create(ref as UpcomingShuttlesRef),
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
  AutoDisposeProviderElement<List<ShuttleEntry>> createElement() {
    return _UpcomingShuttlesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingShuttlesProvider &&
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
mixin UpcomingShuttlesRef on AutoDisposeProviderRef<List<ShuttleEntry>> {
  /// The parameter `route` of this provider.
  ShuttleRoute get route;

  /// The parameter `direction` of this provider.
  ShuttleDirection get direction;
}

class _UpcomingShuttlesProviderElement
    extends AutoDisposeProviderElement<List<ShuttleEntry>>
    with UpcomingShuttlesRef {
  _UpcomingShuttlesProviderElement(super.provider);

  @override
  ShuttleRoute get route => (origin as UpcomingShuttlesProvider).route;
  @override
  ShuttleDirection get direction =>
      (origin as UpcomingShuttlesProvider).direction;
}

String _$shuttleTransfersHash() => r'055fca673cb9521013c6a2a53dbb0d462cf0d657';

/// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
/// 방향이면 null.
///
/// Copied from [shuttleTransfers].
@ProviderFor(shuttleTransfers)
const shuttleTransfersProvider = ShuttleTransfersFamily();

/// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
/// 방향이면 null.
///
/// Copied from [shuttleTransfers].
class ShuttleTransfersFamily extends Family<List<ShuttleConnection>?> {
  /// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
  /// 방향이면 null.
  ///
  /// Copied from [shuttleTransfers].
  const ShuttleTransfersFamily();

  /// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
  /// 방향이면 null.
  ///
  /// Copied from [shuttleTransfers].
  ShuttleTransfersProvider call({required ShuttleDirection direction}) {
    return ShuttleTransfersProvider(direction: direction);
  }

  @override
  ShuttleTransfersProvider getProviderOverride(
    covariant ShuttleTransfersProvider provider,
  ) {
    return call(direction: provider.direction);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shuttleTransfersProvider';
}

/// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
/// 방향이면 null.
///
/// Copied from [shuttleTransfers].
class ShuttleTransfersProvider
    extends AutoDisposeProvider<List<ShuttleConnection>?> {
  /// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
  /// 방향이면 null.
  ///
  /// Copied from [shuttleTransfers].
  ShuttleTransfersProvider({required ShuttleDirection direction})
    : this._internal(
        (ref) =>
            shuttleTransfers(ref as ShuttleTransfersRef, direction: direction),
        from: shuttleTransfersProvider,
        name: r'shuttleTransfersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$shuttleTransfersHash,
        dependencies: ShuttleTransfersFamily._dependencies,
        allTransitiveDependencies:
            ShuttleTransfersFamily._allTransitiveDependencies,
        direction: direction,
      );

  ShuttleTransfersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.direction,
  }) : super.internal();

  final ShuttleDirection direction;

  @override
  Override overrideWith(
    List<ShuttleConnection>? Function(ShuttleTransfersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShuttleTransfersProvider._internal(
        (ref) => create(ref as ShuttleTransfersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        direction: direction,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<ShuttleConnection>?> createElement() {
    return _ShuttleTransfersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShuttleTransfersProvider && other.direction == direction;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, direction.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShuttleTransfersRef on AutoDisposeProviderRef<List<ShuttleConnection>?> {
  /// The parameter `direction` of this provider.
  ShuttleDirection get direction;
}

class _ShuttleTransfersProviderElement
    extends AutoDisposeProviderElement<List<ShuttleConnection>?>
    with ShuttleTransfersRef {
  _ShuttleTransfersProviderElement(super.provider);

  @override
  ShuttleDirection get direction =>
      (origin as ShuttleTransfersProvider).direction;
}

String _$shuttleClockHash() => r'a8f6b0c7df02cab8a24d6bd09e2c028468ebd726';

/// 셔틀 계산의 기준 시각(KST).
///
/// 홈·버스 상세 화면이 공유한다. 분이 바뀔 때마다 자동으로 갱신되므로
/// "N분 후 출발"이 화면을 켜둔 채로도 흘러간다. 당겨서 새로고침이나
/// 백그라운드 복귀처럼 즉시 맞춰야 할 때는 [refresh]를 부른다.
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
String _$shuttleScheduleSourceHash() =>
    r'7c6a09c79ed1a5fe1190f6458fd3a1255fa8f35b';

/// 서버에서 받은 오늘(KST) 셔틀 시간표. null 이면 내장 시간표를 쓴다.
///
/// 대체 순서는 서버 → 기기 캐시 → 내장 시간표다. 앱을 켜면 먼저 마지막 성공
/// 응답(캐시)을 올리고, 이어서 서버에서 받아 바꾼다. 서버가 실패(503 포함)하거나
/// 형식이 계약과 다르면(운영이 아직 옛 형식) 대체 서버에 1회 묻고, 그래도 안
/// 되면 캐시(없으면 내장)를 그대로 둔다. 응답은 날짜별이라
/// [shuttleClockProvider]의 날짜가 바뀌면(자정) 다시 받는다.
///
/// 캐시 본문의 `version`으로 `If-None-Match`를 붙여 304면 캐시를 그대로 쓴다.
/// 다만 version 은 날짜와 무관해 304 는 그날의 `day_type`·구간을 알려 주지
/// 않으므로, 캐시 날짜가 오늘일 때만 붙인다. 다른 날 캐시면 조건 없이 받는다.
///
/// Copied from [ShuttleScheduleSource].
@ProviderFor(ShuttleScheduleSource)
final shuttleScheduleSourceProvider =
    NotifierProvider<ShuttleScheduleSource, RemoteShuttleSchedule?>.internal(
      ShuttleScheduleSource.new,
      name: r'shuttleScheduleSourceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$shuttleScheduleSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ShuttleScheduleSource = Notifier<RemoteShuttleSchedule?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
