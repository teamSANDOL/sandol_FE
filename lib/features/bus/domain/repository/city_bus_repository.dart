import 'package:handori/features/bus/domain/model/bus_arrival.dart';

/// 시내버스 실시간 도착 정보 저장소 추상 인터페이스.
abstract class CityBusRepository {
  /// [stationId] 정류장의 실시간 도착 정보 목록을 조회한다.
  /// 도착 정보가 없으면 빈 리스트를 반환한다.
  Future<List<BusArrival>> getArrivals(int stationId);
}
