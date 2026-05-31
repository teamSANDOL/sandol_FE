import 'package:json_annotation/json_annotation.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';

part 'restaurant_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LocationResponse {
  final bool isCampus;
  final String? building;
  final Map<String, String>? mapLinks;
  final double? latitude;
  final double? longitude;

  const LocationResponse({
    required this.isCampus,
    this.building,
    this.mapLinks,
    this.latitude,
    this.longitude,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LocationResponseToJson(this);

  Location toDomain() => Location(
        isCampus: isCampus,
        building: building,
        mapLinks: mapLinks,
        latitude: latitude,
        longitude: longitude,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TimeRangeResponse {
  final String start;
  final String end;

  const TimeRangeResponse({required this.start, required this.end});

  factory TimeRangeResponse.fromJson(Map<String, dynamic> json) =>
      _$TimeRangeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TimeRangeResponseToJson(this);

  TimeRange toDomain() => TimeRange(start: start, end: end);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RestaurantResponse {
  final int id;
  final String name;
  final String establishmentType;
  final int? price;
  final LocationResponse? location;
  final TimeRangeResponse? openingTime;
  final TimeRangeResponse? breakTime;
  final TimeRangeResponse? breakfastTime;
  final TimeRangeResponse? brunchTime;
  final TimeRangeResponse? lunchTime;
  final TimeRangeResponse? dinnerTime;
  final int? owner;

  const RestaurantResponse({
    required this.id,
    required this.name,
    required this.establishmentType,
    this.price,
    this.location,
    this.openingTime,
    this.breakTime,
    this.breakfastTime,
    this.brunchTime,
    this.lunchTime,
    this.dinnerTime,
    this.owner,
  });

  factory RestaurantResponse.fromJson(Map<String, dynamic> json) =>
      _$RestaurantResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RestaurantResponseToJson(this);

  Restaurant toDomain() => Restaurant(
        id: id,
        name: name,
        establishmentType: establishmentType,
        price: price,
        location: location?.toDomain(),
        openingTime: openingTime?.toDomain(),
        breakTime: breakTime?.toDomain(),
        breakfastTime: breakfastTime?.toDomain(),
        brunchTime: brunchTime?.toDomain(),
        lunchTime: lunchTime?.toDomain(),
        dinnerTime: dinnerTime?.toDomain(),
        owner: owner,
      );
}
