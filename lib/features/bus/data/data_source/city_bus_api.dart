import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/bus/data/dto/bus_arrival_response.dart';

part 'city_bus_api.g.dart';

/// 공공데이터포털 경기도(6410000) 버스도착정보 조회 API.
///
/// baseUrl(host)은 [gyeonggiBusDio]에서 주입하고, 인증키([serviceKey])는
/// `.env`의 `GYEONGGI_BUS_API_KEY`를 호출부(provider)에서 주입한다.
@RestApi()
abstract class CityBusApi {
  factory CityBusApi(Dio dio, {String? baseUrl}) = _CityBusApi;

  /// 특정 정류장([stationId])에 도착 예정인 모든 노선의 실시간 정보.
  @GET('/busarrivalservice/v2/getBusArrivalListv2')
  Future<BusArrivalResponse> getBusArrivalList(
    @Query('serviceKey') String serviceKey,
    @Query('stationId') int stationId, {
    @Query('format') String format = 'json',
  });
}
