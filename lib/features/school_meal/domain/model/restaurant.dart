/// 식당 위치 정보 (value object)
class Location {
  final bool isCampus;
  final String? building;
  final Map<String, String>? mapLinks;
  final double? latitude;
  final double? longitude;

  const Location({
    required this.isCampus,
    this.building,
    this.mapLinks,
    this.latitude,
    this.longitude,
  });
}

/// 시간 범위 ("HH:MM" 문자열) value object
class TimeRange {
  final String start;
  final String end;

  const TimeRange({required this.start, required this.end});
}

/// 식당 도메인 모델
class Restaurant {
  final int id;
  final String name;
  final String establishmentType;
  final int? price;
  final Location? location;
  final TimeRange? openingTime;
  final TimeRange? breakTime;
  final TimeRange? breakfastTime;
  final TimeRange? brunchTime;
  final TimeRange? lunchTime;
  final TimeRange? dinnerTime;
  final int? owner;

  /// 식당 사진 주소(절대 주소로 풀린 값). 서버 `image_url`이 없으면 null 이고,
  /// 그때 화면은 식당 이름으로 찾은 앱 에셋을 쓴다.
  final String? imageUrl;

  const Restaurant({
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

  /// 위치 표기용 문자열 (예: "E동")
  String? get locationLabel => location?.building;
}
