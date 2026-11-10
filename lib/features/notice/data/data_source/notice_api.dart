import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handol/features/notice/data/dto/paginated_notice_response.dart';

part 'notice_api.g.dart';

@RestApi()
abstract class NoticeApi {
  factory NoticeApi(Dio dio, {String? baseUrl}) = _NoticeApi;

  @GET('/notice-notification/notice')
  Future<PaginatedNoticeResponse> getNotices(
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET('/notice-notification/dormitory-notice')
  Future<PaginatedNoticeResponse> getDormitoryNotices(
    @Query('page') int page,
    @Query('size') int size,
  );
}
