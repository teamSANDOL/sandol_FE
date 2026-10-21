// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuk_place.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TukPlace _$TukPlaceFromJson(Map<String, dynamic> json) => TukPlace(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  category: json['category'] as String?,
  address: json['address'] as String?,
  naverMapUrl: json['naver_map_url'] as String?,
  kakaoMapUrl: json['kakao_map_url'] as String?,
  discountInfo: json['discount_info'] as String?,
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => TukPlaceImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

TukPlaceImage _$TukPlaceImageFromJson(Map<String, dynamic> json) =>
    TukPlaceImage(url: json['url'] as String);
