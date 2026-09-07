import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/empty_class/data/dto/available_classrooms_response.dart';
import 'package:handori/features/empty_class/data/dto/building_classrooms_response.dart';

part 'classroom_api.g.dart';

/// 강의실 시간표 서비스 (teamSANDOL/sandol_classroom_timetable, Express).
///
/// baseUrl 은 host 만 두고 경로에 `/classroom-timetable/` 을 포함한다
/// (static-info 와 같은 Dio 규칙). Swagger 없음 — 스펙은 Notion 문서와 소스.
/// `day` 는 `월요일`~`일요일` 전체 표기, 인증 불필요.
@RestApi()
abstract class ClassroomApi {
  factory ClassroomApi(Dio dio, {String? baseUrl}) = _ClassroomApi;

  /// 시간표에 등장하는 건물별 전체 강의실
  @GET('/classroom-timetable/classrooms')
  Future<List<BuildingClassroomsResponse>> getClassrooms();

  /// N교시 기반 (1~14). 양끝 포함. building 생략 시 전체 건물.
  @GET('/classroom-timetable/classrooms/available/periods')
  Future<List<AvailableClassroomsResponse>> getAvailableByPeriods({
    @Query('day') required String day,
    @Query('start_time') required String startPeriod,
    @Query('end_time') required String endPeriod,
    @Query('building') String? building,
  });

  /// 시각 기반 (`HH:MM`). building 생략 시 전체 건물.
  @GET('/classroom-timetable/classrooms/available/time')
  Future<List<AvailableClassroomsResponse>> getAvailableByTime({
    @Query('day') required String day,
    @Query('start_time') required String startTime,
    @Query('end_time') required String endTime,
    @Query('building') String? building,
  });
}
