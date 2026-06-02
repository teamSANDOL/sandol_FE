// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_restaurant_id_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedRestaurantIdHash() =>
    r'1b068c369552494f6c5e2df51161644c08bdf11b';

/// 홈 화면 식당 칩과 학식 상세 페이지 탭 간 선택 상태를 공유하는 전역 노티파이어.
///
/// §2.3 규약에 따라 수동 `StateProvider` 대신 `@riverpod` 코드 생성 방식을 사용한다.
/// 선택된 식당 ID(`restaurant.id`)를 보관하며, 화면 전환 후에도 선택이 유지돼야
/// 하므로 `keepAlive: true` 로 살린다. `null`이면 아직 선택이 없음을 의미한다.
///
/// Copied from [SelectedRestaurantId].
@ProviderFor(SelectedRestaurantId)
final selectedRestaurantIdProvider =
    NotifierProvider<SelectedRestaurantId, int?>.internal(
      SelectedRestaurantId.new,
      name: r'selectedRestaurantIdProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedRestaurantIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedRestaurantId = Notifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
