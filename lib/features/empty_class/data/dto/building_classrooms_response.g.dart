// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_classrooms_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildingClassroomsResponse _$BuildingClassroomsResponseFromJson(
  Map<String, dynamic> json,
) => BuildingClassroomsResponse(
  building: json['building'] as String,
  classrooms:
      (json['classrooms'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$BuildingClassroomsResponseToJson(
  BuildingClassroomsResponse instance,
) => <String, dynamic>{
  'building': instance.building,
  'classrooms': instance.classrooms,
};
