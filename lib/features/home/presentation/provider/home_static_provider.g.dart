// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_static_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleEventsHash() => r'd50bf59f596cdbd30ad8c5fed375b29d485a0452';

/// See also [scheduleEvents].
@ProviderFor(scheduleEvents)
final scheduleEventsProvider =
    AutoDisposeProvider<List<ScheduleEvent>>.internal(
      scheduleEvents,
      name: r'scheduleEventsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$scheduleEventsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScheduleEventsRef = AutoDisposeProviderRef<List<ScheduleEvent>>;
String _$homeScheduleHash() => r'8206978ce2d87c29f4d73dc5cd06f246f16a5508';

/// 홈 주요일정: 끝나지 않았고 고정을 해제하지 않은 것 중 가장 먼저
/// 시작하는 것. 없으면 null(빈 카드). 해제 목록을 읽는 동안은 로딩이라
/// 빈 카드가 잠깐 보였다 바뀌지 않는다.
///
/// Copied from [homeSchedule].
@ProviderFor(homeSchedule)
final homeScheduleProvider = AutoDisposeFutureProvider<ScheduleEvent?>.internal(
  homeSchedule,
  name: r'homeScheduleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeScheduleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeScheduleRef = AutoDisposeFutureProviderRef<ScheduleEvent?>;
String _$dismissedSchedulesHash() =>
    r'd75f1c792fa3e3c277776b2df91a4190870bfb4e';

/// 고정을 해제한 일정 id. 기기에 저장해 앱을 다시 켜도 해제된 채로 둔다.
///
/// Copied from [DismissedSchedules].
@ProviderFor(DismissedSchedules)
final dismissedSchedulesProvider =
    AsyncNotifierProvider<DismissedSchedules, Set<String>>.internal(
      DismissedSchedules.new,
      name: r'dismissedSchedulesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$dismissedSchedulesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DismissedSchedules = AsyncNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
