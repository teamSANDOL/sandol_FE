// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shuttle_direction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shuttleDirectionSelectionHash() =>
    r'32c33cc16e62d62a1e586b39589f5d0188f349fe';

/// 노선1 방향 선택. 홈 카드와 셔틀 상세 화면이 공유한다.
///
/// 위치를 얻으면 가까운 정류장을 출발지로 기본 선택하되, 사용자가 직접 바꾼
/// 뒤에는 위치가 갱신돼도 되돌리지 않는다. 위치는 홈이 이미 요청하는
/// [userLocationProvider]를 구독만 하므로 이 기능이 권한 창을 새로 띄우지 않는다.
/// 정류장 좌표는 [shuttleStopsProvider](서버 `stops`, 없으면 내장)를 쓴다.
///
/// Copied from [ShuttleDirectionSelection].
@ProviderFor(ShuttleDirectionSelection)
final shuttleDirectionSelectionProvider =
    NotifierProvider<ShuttleDirectionSelection, ShuttleDirection>.internal(
      ShuttleDirectionSelection.new,
      name: r'shuttleDirectionSelectionProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$shuttleDirectionSelectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ShuttleDirectionSelection = Notifier<ShuttleDirection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
