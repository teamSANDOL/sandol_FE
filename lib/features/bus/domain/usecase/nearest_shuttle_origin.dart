import 'package:geolocator/geolocator.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 현재 위치에서 가까운 정류장을 노선1 출발지(방향)로 고르는 순수 로직.
class NearestShuttleOrigin {
  const NearestShuttleOrigin._();

  // 좌표는 OpenStreetMap(Nominatim) 검색 기준이다.
  // 학교: '한국공학대학교' 캠퍼스 중심점. 정문 정류장 좌표는 지도에 따로 없어
  //       캠퍼스 중심으로 근사한다(두 정류장은 1.2km 이상 떨어져 있다).
  // 정왕역: OSM 버스 정류장 노드 '정왕역'.
  static const double schoolLat = 37.3402397;
  static const double schoolLng = 126.7333516;
  static const double stationLat = 37.3512712;
  static const double stationLng = 126.7411157;

  /// [lat]·[lng]에서 더 가까운 정류장을 출발지로 하는 방향.
  static ShuttleDirection fromPosition(double lat, double lng) {
    final toSchool = Geolocator.distanceBetween(lat, lng, schoolLat, schoolLng);
    final toStation = Geolocator.distanceBetween(
      lat,
      lng,
      stationLat,
      stationLng,
    );
    return toStation < toSchool
        ? ShuttleDirection.jeongwangToSchool
        : ShuttleDirection.schoolToJeongwang;
  }
}
