/// 홈 카드 건물 정렬 방식.
enum BuildingSort {
  /// 내 위치에서 가까운 순 (위치를 모르면 빈 강의실 많은 순으로 대체)
  distance('내 위치 정렬'),

  /// 빈 강의실 많은 순
  count('빈 강의실 많은 순'),

  /// 사용자가 직접 끌어 정한 순서
  custom('내 순서 정렬');

  final String label;
  const BuildingSort(this.label);
}

/// 정렬 설정. 기기 로컬에 저장되며 서버와 무관하다.
class BuildingSortSettings {
  final BuildingSort mode;

  /// [BuildingSort.custom] 에서 쓰는 건물명 순서. 없는 건물은 뒤로 간다.
  final List<String> customOrder;

  const BuildingSortSettings({
    this.mode = BuildingSort.distance,
    this.customOrder = const [],
  });

  BuildingSortSettings copyWith({
    BuildingSort? mode,
    List<String>? customOrder,
  }) {
    return BuildingSortSettings(
      mode: mode ?? this.mode,
      customOrder: customOrder ?? this.customOrder,
    );
  }

  /// [name] 의 순위. 저장된 순서에 없으면 가장 뒤.
  int rankOf(String name) {
    final i = customOrder.indexOf(name);
    return i < 0 ? customOrder.length : i;
  }
}
