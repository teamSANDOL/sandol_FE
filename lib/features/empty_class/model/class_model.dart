class EmptyClass {
  /// 백엔드 건물명 (예: `E동`, `산융`, `TIP`)
  final String className;

  /// 빈 강의실 수. 기존 UI 호환을 위해 문자열로 유지한다.
  final String classCount;

  /// 여유/보통/혼잡 배지 자산 경로 (빈 강의실 비율로 산출)
  final String trafficIcon;
  final String classIcons;

  /// 건물 좌표. 좌표 테이블에 없는 건물은 null → 지도 마커·거리 계산 생략.
  final double? latitude;
  final double? longitude;

  /// 조회 구간 내내 비어 있는 강의실 (예: `217호`)
  final List<String> classList;

  /// 건물 전체 강의실 수 (시간표에 등장하는 강의실 기준). 모르면 0.
  final int totalCount;

  const EmptyClass({
    required this.className,
    required this.classCount,
    required this.trafficIcon,
    required this.classIcons,
    required this.classList,
    required this.latitude,
    required this.longitude,
    this.totalCount = 0,
  });

  int get emptyCount => int.tryParse(classCount.trim()) ?? classList.length;

  bool get hasLocation => latitude != null && longitude != null;
}
