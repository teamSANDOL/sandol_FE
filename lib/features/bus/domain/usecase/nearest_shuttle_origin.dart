import 'package:geolocator/geolocator.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 현재 위치에서 가까운 정류장을 노선1 출발지(방향)로 고르는 순수 로직.
class NearestShuttleOrigin {
  const NearestShuttleOrigin._();

  /// [lat]·[lng]에서 더 가까운 정류장을 출발지로 하는 방향. [stops]는 서버
  /// 정류장 id → 정류장이고, 좌표가 없는 정류장은 판정에서 뺀다. 둘 다
  /// 좌표가 없으면 기본값(학교 출발).
  static ShuttleDirection fromPosition(
    double lat,
    double lng,
    Map<String, ShuttleStop> stops,
  ) {
    double? distanceTo(String id) {
      final stopLat = stops[id]?.lat;
      final stopLng = stops[id]?.lng;
      if (stopLat == null || stopLng == null) return null;
      return Geolocator.distanceBetween(lat, lng, stopLat, stopLng);
    }

    final toSchool = distanceTo('main_campus');
    final toStation = distanceTo('jeongwang');
    if (toStation == null) return ShuttleDirection.schoolToJeongwang;
    return toSchool == null || toStation < toSchool
        ? ShuttleDirection.jeongwangToSchool
        : ShuttleDirection.schoolToJeongwang;
  }
}
