import 'package:handori/features/empty_class/model/class_model.dart';

/// 홈 카드용: 건물별 빈 강의실 + 내 위치로부터의 거리.
class NearbyEmptyClass {
  final EmptyClass building;

  /// 내 위치를 모르거나 건물 좌표가 없으면 null
  final double? distanceMeters;

  const NearbyEmptyClass({required this.building, this.distanceMeters});

  /// 캠퍼스 보행 속도(약 70m/분) 기준 도보 시간. 최소 1분.
  int? get walkMinutes {
    final d = distanceMeters;
    if (d == null) return null;
    return (d / 70).ceil().clamp(1, 99);
  }
}
