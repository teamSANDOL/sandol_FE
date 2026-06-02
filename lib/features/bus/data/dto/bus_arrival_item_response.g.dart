// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_arrival_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusArrivalItemResponse _$BusArrivalItemResponseFromJson(
  Map<String, dynamic> json,
) => BusArrivalItemResponse(
  routeId: _intOrZero(json['routeId']),
  routeName: _stringOrEmpty(json['routeName']),
  routeDestName: _stringOrNull(json['routeDestName']),
  flag: _stringOrNull(json['flag']),
  predictTime1: _intOrNull(json['predictTime1']),
  locationNo1: _intOrNull(json['locationNo1']),
  plateNo1: _stringOrNull(json['plateNo1']),
  lowPlate1: _intOrNull(json['lowPlate1']),
  remainSeatCnt1: _intOrNull(json['remainSeatCnt1']),
  crowded1: _intOrNull(json['crowded1']),
  predictTime2: _intOrNull(json['predictTime2']),
  locationNo2: _intOrNull(json['locationNo2']),
  plateNo2: _stringOrNull(json['plateNo2']),
  lowPlate2: _intOrNull(json['lowPlate2']),
  remainSeatCnt2: _intOrNull(json['remainSeatCnt2']),
  crowded2: _intOrNull(json['crowded2']),
);

Map<String, dynamic> _$BusArrivalItemResponseToJson(
  BusArrivalItemResponse instance,
) => <String, dynamic>{
  'routeId': instance.routeId,
  'routeName': instance.routeName,
  'routeDestName': instance.routeDestName,
  'flag': instance.flag,
  'predictTime1': instance.predictTime1,
  'locationNo1': instance.locationNo1,
  'plateNo1': instance.plateNo1,
  'lowPlate1': instance.lowPlate1,
  'remainSeatCnt1': instance.remainSeatCnt1,
  'crowded1': instance.crowded1,
  'predictTime2': instance.predictTime2,
  'locationNo2': instance.locationNo2,
  'plateNo2': instance.plateNo2,
  'lowPlate2': instance.lowPlate2,
  'remainSeatCnt2': instance.remainSeatCnt2,
  'crowded2': instance.crowded2,
};
