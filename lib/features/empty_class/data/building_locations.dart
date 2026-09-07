/// 백엔드 건물명 → 캠퍼스 좌표·아이콘.
///
/// 좌표는 OpenStreetMap 건물 폴리곤 중심(2026-09 조회). 백엔드 `buildings.csv`
/// 의 건물명을 키로 쓴다. 표에 없는 건물은 좌표 없이 목록에만 나온다.
class BuildingLocation {
  final double latitude;
  final double longitude;
  final String icon;

  const BuildingLocation(this.latitude, this.longitude, this.icon);
}

const String _defaultIcon = 'assets/img/emptyclass_filled.png';

const Map<String, BuildingLocation> buildingLocations = {
  'A동': BuildingLocation(37.340429, 126.732890, 'assets/img/tino6.png'),
  'B동': BuildingLocation(37.340353, 126.733302, 'assets/img/tukorea_Materials.png'),
  'C동': BuildingLocation(37.340009, 126.733987, 'assets/img/tukorea_Energy.png'),
  'D동': BuildingLocation(37.339689, 126.734144, 'assets/img/tukorea_Electronic.png'),
  'E동': BuildingLocation(37.339713, 126.735044, 'assets/img/tukorea_computer.png'),
  'G동': BuildingLocation(37.340264, 126.734741, 'assets/img/tukorea_Mechanical.png'),
  'P동': BuildingLocation(37.339414, 126.735535, _defaultIcon),
  // 제2기숙사(TIP)
  'TIP': BuildingLocation(37.341316, 126.732924, _defaultIcon),
  // 산학융합본부
  '산융': BuildingLocation(37.338704, 126.734550, _defaultIcon),
  // 종합교육관 (중앙도서관 포함). 백엔드 별칭: 종합·종관·중도·도서관
  '중앙': BuildingLocation(37.340667, 126.734094, _defaultIcon),
  // 시흥비즈니스센터
  '비즈': BuildingLocation(37.340004, 126.732361, _defaultIcon),
  // '미래', '제2생' 은 좌표 미확인 — 현재 시간표에 강의가 없어 응답에도 없음
};

/// 좌표 표의 순서 = 캠퍼스 순회 순서. 응답 정렬의 기본값으로 쓴다.
int buildingOrder(String name) {
  final idx = buildingLocations.keys.toList().indexOf(name);
  return idx < 0 ? buildingLocations.length : idx;
}

String buildingIcon(String name) =>
    buildingLocations[name]?.icon ?? _defaultIcon;
