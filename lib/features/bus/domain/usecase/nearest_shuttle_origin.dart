import 'package:geolocator/geolocator.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 현재 위치에서 가장 가까운 정류장을 출발지(방향)로 고르는 순수 로직.
class NearestShuttleOrigin {
  const NearestShuttleOrigin._();

  /// [lat]·[lng]에서 가장 가까운 정류장을 출발지로 하는 방향. [stops]는 서버
  /// 정류장 id → 정류장이고, 좌표가 없는 정류장은 판정에서 뺀다(지금 서버는
  /// 제2캠퍼스 좌표가 null). 학교·정왕역이면 정왕역 노선, 제2캠퍼스면 본교행.
  /// 좌표가 하나도 없으면 기본값(학교 출발).
  static ShuttleDirection fromPosition(
    double lat,
    double lng,
    Map<String, ShuttleStop> stops,
  ) {
    String? nearest;
    var best = double.infinity;
    for (final id in const ['main_campus', 'jeongwang', 'campus2']) {
      final stopLat = stops[id]?.lat;
      final stopLng = stops[id]?.lng;
      if (stopLat == null || stopLng == null) continue;
      final d = Geolocator.distanceBetween(lat, lng, stopLat, stopLng);
      if (d < best) (nearest, best) = (id, d);
    }
    return switch (nearest) {
      'jeongwang' => ShuttleDirection.jeongwangToSchool,
      'campus2' => ShuttleDirection.campus2ToSchool,
      _ => ShuttleDirection.schoolToJeongwang,
    };
  }
}
