import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/map/data/tuk_place.dart';

part 'tuk_world_api.g.dart';

/// static-info 서비스의 TUK 월드 API. 조회는 인증이 필요 없다.
@RestApi()
abstract class TukWorldApi {
  factory TukWorldApi(Dio dio, {String? baseUrl}) = _TukWorldApi;

  /// 등록된 제휴 업체 전체 (id 순)
  @GET('/static-info/tuk-world/restaurants')
  Future<List<TukPlace>> getPlaces();
}
