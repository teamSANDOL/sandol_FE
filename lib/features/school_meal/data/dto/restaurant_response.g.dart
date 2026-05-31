// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationResponse _$LocationResponseFromJson(Map<String, dynamic> json) =>
    LocationResponse(
      isCampus: json['is_campus'] as bool,
      building: json['building'] as String?,
      mapLinks: (json['map_links'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LocationResponseToJson(LocationResponse instance) =>
    <String, dynamic>{
      'is_campus': instance.isCampus,
      'building': instance.building,
      'map_links': instance.mapLinks,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

TimeRangeResponse _$TimeRangeResponseFromJson(Map<String, dynamic> json) =>
    TimeRangeResponse(
      start: json['start'] as String,
      end: json['end'] as String,
    );

Map<String, dynamic> _$TimeRangeResponseToJson(TimeRangeResponse instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

RestaurantResponse _$RestaurantResponseFromJson(Map<String, dynamic> json) =>
    RestaurantResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      establishmentType: json['establishment_type'] as String,
      price: (json['price'] as num?)?.toInt(),
      location:
          json['location'] == null
              ? null
              : LocationResponse.fromJson(
                json['location'] as Map<String, dynamic>,
              ),
      openingTime:
          json['opening_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['opening_time'] as Map<String, dynamic>,
              ),
      breakTime:
          json['break_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['break_time'] as Map<String, dynamic>,
              ),
      breakfastTime:
          json['breakfast_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['breakfast_time'] as Map<String, dynamic>,
              ),
      brunchTime:
          json['brunch_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['brunch_time'] as Map<String, dynamic>,
              ),
      lunchTime:
          json['lunch_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['lunch_time'] as Map<String, dynamic>,
              ),
      dinnerTime:
          json['dinner_time'] == null
              ? null
              : TimeRangeResponse.fromJson(
                json['dinner_time'] as Map<String, dynamic>,
              ),
      owner: (json['owner'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RestaurantResponseToJson(RestaurantResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'establishment_type': instance.establishmentType,
      'price': instance.price,
      'location': instance.location,
      'opening_time': instance.openingTime,
      'break_time': instance.breakTime,
      'breakfast_time': instance.breakfastTime,
      'brunch_time': instance.brunchTime,
      'lunch_time': instance.lunchTime,
      'dinner_time': instance.dinnerTime,
      'owner': instance.owner,
    };
