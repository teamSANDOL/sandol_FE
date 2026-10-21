import 'package:json_annotation/json_annotation.dart';
import 'package:handori/core/constants/api_constants.dart';
import 'package:handori/core/utils/remote_url.dart';
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

  /// 식당 사진. 절대 주소 또는 학식 서버 기준 경로. 아직 서버에 없는 필드다.
  final String? imageUrl;

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
    this.imageUrl,
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
    imageUrl: resolveMealImageUrl(imageUrl),
  );
}

/// 학식 응답(식당·끼니)의 이미지 경로를 절대 주소로 푼다. 빈 값은 없는 것으로 본다.
// ponytail: 학식 API는 realUri 를 받지 않아 대체 서버가 응답해도 운영 주소로
// 푼다. 서버가 절대 주소를 주면 상관없다.
String? resolveMealImageUrl(String? url) =>
    url == null || url.isEmpty
        ? null
        : resolveRemoteUrl(url, Uri.parse(ApiConstants.mealBaseUrl));
