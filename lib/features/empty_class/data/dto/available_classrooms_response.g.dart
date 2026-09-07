// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_classrooms_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableClassroomsResponse _$AvailableClassroomsResponseFromJson(
  Map<String, dynamic> json,
) => AvailableClassroomsResponse(
  building: json['building'] as String,
  emptyClassrooms:
      (json['empty_classrooms'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$AvailableClassroomsResponseToJson(
  AvailableClassroomsResponse instance,
) => <String, dynamic>{
  'building': instance.building,
  'empty_classrooms': instance.emptyClassrooms,
};
