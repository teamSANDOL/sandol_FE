import 'package:handori/features/bus/data/data_source/city_bus_api.dart';
import 'package:handori/features/bus/domain/model/bus_arrival.dart';
import 'package:handori/features/bus/domain/repository/city_bus_repository.dart';

/// 경기도 버스도착정보 API 기반 [CityBusRepository] 구현.
class CityBusRepositoryImpl implements CityBusRepository {
  final CityBusApi _api;
  final String _serviceKey;

  const CityBusRepositoryImpl(this._api, this._serviceKey);

  @override
  Future<List<BusArrival>> getArrivals(int stationId) async {
    final response = await _api.getBusArrivalList(_serviceKey, stationId);

    // resultCode 4 등(도착 정보 없음)은 빈 목록으로 처리, 그 외 비정상은 예외.
    if (!response.isSuccess) {
      if (response.resultCode == _noResultCode) return const [];
      throw Exception(
        '버스 도착정보 조회 실패 (${response.resultCode}): ${response.resultMessage}',
      );
    }
    return response.toDomain();
  }

  /// GBIS: 결과가 없습니다(데이터 미존재).
  static const int _noResultCode = 4;
}
