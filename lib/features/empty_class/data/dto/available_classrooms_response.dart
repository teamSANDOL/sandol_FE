import 'package:json_annotation/json_annotation.dart';

part 'available_classrooms_response.g.dart';

/// `GET /classroom-timetable/classrooms/available/{time|periods}` 항목.
/// 조회 구간 내내 비어 있는 강의실 목록.
@JsonSerializable()
class AvailableClassroomsResponse {
  final String building;

  @JsonKey(name: 'empty_classrooms')
  final List<String> emptyClassrooms;

  const AvailableClassroomsResponse({
    required this.building,
    required this.emptyClassrooms,
  });

  factory AvailableClassroomsResponse.fromJson(Map<String, dynamic> json) =>
      _$AvailableClassroomsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AvailableClassroomsResponseToJson(this);
}
