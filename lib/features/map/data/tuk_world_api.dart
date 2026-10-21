import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/map/data/tuk_place.dart';

part 'tuk_world_api.g.dart';

/// static-info 서비스의 TUK 월드 API. 조회는 인증이 필요 없다.
@RestApi()
abstract class TukWorldApi {
  factory TukWorldApi(Dio dio, {String? baseUrl}) = _TukWorldApi;

  /// 등록된 제휴 업체 전체 (id 순). 응답을 실제로 준 서버(`realUri`)를 알아야
  /// 상대 경로 이미지를 풀 수 있어 [HttpResponse]로 받는다.
  @GET('/static-info/tuk-world/restaurants')
  Future<HttpResponse<List<TukPlace>>> getPlaces();
}
