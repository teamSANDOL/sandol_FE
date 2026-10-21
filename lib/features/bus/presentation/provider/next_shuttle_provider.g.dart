// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_shuttle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shuttleTimetableHash() => r'c47a65afe30f082cba778427e5ded1790814deb3';

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
/// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
/// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
/// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
/// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
/// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
/// 이 조건은 저절로 풀린다.
/// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
/// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
/// 공휴일인지는 알려 주지 않기 때문이다.
///
/// Copied from [shuttleTimetable].
@ProviderFor(shuttleTimetable)
const shuttleTimetableProvider = ShuttleTimetableFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
/// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
/// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
/// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
/// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
/// 이 조건은 저절로 풀린다.
/// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
/// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
/// 공휴일인지는 알려 주지 않기 때문이다.
///
/// Copied from [shuttleTimetable].
class ShuttleTimetableFamily extends Family<ShuttleTimetable?> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
  /// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
  /// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
  /// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
  /// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
  /// 이 조건은 저절로 풀린다.
  /// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
  /// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
  /// 공휴일인지는 알려 주지 않기 때문이다.
  ///
  /// Copied from [shuttleTimetable].
  const ShuttleTimetableFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
  /// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
  /// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
  /// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
  /// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
  /// 이 조건은 저절로 풀린다.
  /// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
  /// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
  /// 공휴일인지는 알려 주지 않기 때문이다.
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
/// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
/// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
/// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
/// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
/// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
/// 이 조건은 저절로 풀린다.
/// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
/// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
/// 공휴일인지는 알려 주지 않기 때문이다.
///
/// Copied from [shuttleTimetable].
class ShuttleTimetableProvider extends AutoDisposeProvider<ShuttleTimetable?> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
  ///
  /// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
  /// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
  /// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
  /// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
  /// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
  /// 이 조건은 저절로 풀린다.
  /// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
  /// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
  /// 공휴일인지는 알려 주지 않기 때문이다.
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

String _$nextShuttleHash() => r'496812445c24f6acc007b2368841023f26a66be6';

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
@ProviderFor(nextShuttle)
const nextShuttleProvider = NextShuttleFamily();

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
class NextShuttleFamily extends Family<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
  /// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
  ///
  /// Copied from [nextShuttle].
  const NextShuttleFamily();

  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
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
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
///
/// Copied from [nextShuttle].
class NextShuttleProvider extends AutoDisposeProvider<NextShuttle> {
  /// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
  ///
  /// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
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
    r'd1ae00146a43c8fe5ec9f9b9c9713f5a827fe7ae';

/// 서버에서 받은 셔틀 시간표. null 이면 내장 시간표를 쓴다.
///
/// 대체 순서는 서버 → 기기 캐시 → 내장 시간표다. 앱을 켜면 먼저 마지막 성공
/// 응답(캐시)을 올리고, 이어서 서버에서 받아 바꾼다. 서버가 실패하거나 쓸 수
/// 있는 노선이 없으면 캐시(없으면 내장)를 그대로 둔다. 시간표는 학기 단위로
/// 바뀌므로 앱 실행마다 한 번만 받는다.
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
