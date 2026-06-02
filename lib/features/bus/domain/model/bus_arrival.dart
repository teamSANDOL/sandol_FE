/// 시내버스 실시간 도착 정보 도메인 모델.
///
/// 순수 도메인 계층. presentation/UI는 이 모델만 참조하며 DTO를 직접 보지 않는다.
library;

/// 한 정류장에 도착 예정인 노선 1개의 실시간 정보.
class BusArrival {
  /// 노선 ID (GBIS routeId).
  final int routeId;

  /// 노선 번호 (예: "3-1", "602-1A").
  final String routeName;

  /// 노선 종점(방면) 이름. 없을 수 있음.
  final String? destinationName;

  /// 운행 중 여부(미운행 시 도착 정보 무의미).
  final bool isRunning;

  /// 첫번째 도착 예정 차량. 배차 정보가 없으면 null.
  final BusArrivalPrediction? first;

  /// 두번째 도착 예정 차량. 없으면 null.
  final BusArrivalPrediction? second;

  const BusArrival({
    required this.routeId,
    required this.routeName,
    required this.isRunning,
    this.destinationName,
    this.first,
    this.second,
  });

  /// 표시할 도착 정보(첫번째 차량)가 있는지.
  bool get hasArrival => first != null;
}

/// 도착 예정 차량 1대의 정보.
class BusArrivalPrediction {
  /// 도착까지 남은 시간(분).
  final int predictMinutes;

  /// 남은 정류장 수. 없을 수 있음.
  final int? remainingStops;

  /// 차량 번호판. 없을 수 있음.
  final String? plateNo;

  /// 저상버스 여부.
  final bool isLowFloor;

  /// 빈자리 수. 정보 없음(-1)이면 null.
  final int? remainSeats;

  /// 혼잡도. 0=정보없음, 1=여유, 2=보통, 3=혼잡.
  final int crowdLevel;

  const BusArrivalPrediction({
    required this.predictMinutes,
    required this.isLowFloor,
    required this.crowdLevel,
    this.remainingStops,
    this.plateNo,
    this.remainSeats,
  });
}
