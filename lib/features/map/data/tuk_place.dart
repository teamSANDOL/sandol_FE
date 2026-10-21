import 'package:json_annotation/json_annotation.dart';
import 'package:handori/core/constants/api_constants.dart';

part 'tuk_place.g.dart';

/// TUK 월드(총학생회 제휴 업체) 한 곳.
/// `GET /static-info/tuk-world/restaurants` 항목 (static-info `RestaurantOut`).
@JsonSerializable(createToJson: false)
class TukPlace {
  final int id;
  final String name;

  /// 분류. 서버는 자유 문자열이지만 현재 `식당`·`술집`·`여가`를 쓴다.
  final String? category;
  final String? address;
  @JsonKey(name: 'naver_map_url')
  final String? naverMapUrl;
  @JsonKey(name: 'kakao_map_url')
  final String? kakaoMapUrl;
  final double latitude;
  final double longitude;

  /// 제휴 혜택. 형식 자유, 줄바꿈 포함
  @JsonKey(name: 'discount_info')
  final String? discountInfo;
  final List<TukPlaceImage> images;

  const TukPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.category,
    this.address,
    this.naverMapUrl,
    this.kakaoMapUrl,
    this.discountInfo,
    this.images = const [],
  });

  factory TukPlace.fromJson(Map<String, dynamic> json) =>
      _$TukPlaceFromJson(json);

  /// 이미지 경로를 [base] 기준 절대 주소로 푼 사본. 목록을 대체 서버가 줬다면
  /// 이미지도 그 서버에 있으므로, 운영 주소가 아니라 응답을 준 주소로 푼다.
  TukPlace withImagesResolvedAgainst(Uri base) => TukPlace(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    category: category,
    address: address,
    naverMapUrl: naverMapUrl,
    kakaoMapUrl: kakaoMapUrl,
    discountInfo: discountInfo,
    images: [
      for (final img in images)
        TukPlaceImage(url: base.resolve(img.url).toString()),
    ],
  );

  /// 이미지 주소. 서버에 공개 주소가 설정돼 있지 않으면 경로만 오므로
  /// (아직 안 풀렸다면) static-info 호스트 기준으로 풀어 준다.
  List<String> get imageUrls => [
    for (final img in images)
      Uri.parse(ApiConstants.staticInfoBaseUrl).resolve(img.url).toString(),
  ];
}

@JsonSerializable(createToJson: false)
class TukPlaceImage {
  final String url;

  const TukPlaceImage({required this.url});

  factory TukPlaceImage.fromJson(Map<String, dynamic> json) =>
      _$TukPlaceImageFromJson(json);
}
