import 'package:json_annotation/json_annotation.dart';

part 'building_classrooms_response.g.dart';

/// `GET /classroom-timetable/classrooms` 항목. 건물별 전체 강의실.
@JsonSerializable()
class BuildingClassroomsResponse {
  final String building;
  final List<String> classrooms;

  const BuildingClassroomsResponse({
    required this.building,
    required this.classrooms,
  });

  factory BuildingClassroomsResponse.fromJson(Map<String, dynamic> json) =>
      _$BuildingClassroomsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BuildingClassroomsResponseToJson(this);
}
