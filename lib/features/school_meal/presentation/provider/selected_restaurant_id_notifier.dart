import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_restaurant_id_notifier.g.dart';

/// 홈 화면 식당 칩과 학식 상세 페이지 탭 간 선택 상태를 공유하는 전역 노티파이어.
///
/// §2.3 규약에 따라 수동 `StateProvider` 대신 `@riverpod` 코드 생성 방식을 사용한다.
/// 선택된 식당 ID(`restaurant.id`)를 보관하며, 화면 전환 후에도 선택이 유지돼야
/// 하므로 `keepAlive: true` 로 살린다. `null`이면 아직 선택이 없음을 의미한다.
@Riverpod(keepAlive: true)
class SelectedRestaurantId extends _$SelectedRestaurantId {
  @override
  int? build() => null;

  /// 선택된 식당 ID를 갱신한다.
  void select(int? id) => state = id;
}
