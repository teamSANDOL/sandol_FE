import 'package:json_annotation/json_annotation.dart';
import 'package:handori/features/bus/domain/model/bus_arrival.dart';

part 'bus_arrival_item_response.g.dart';

/// 경기도 버스도착정보 `busArrivalList` 항목 1건.
///
/// 한 정류장에 도착 예정인 노선 1개의 정보. 첫번째(`*1`)·두번째(`*2`) 차량을
/// 함께 제공한다. 두번째 차량이 없으면 서버가 숫자 필드를 빈 문자열(`""`)로
/// 내려주므로, 정수 필드는 [_intOrNull]로 `""`/null을 모두 null 처리한다.
@JsonSerializable()
class BusArrivalItemResponse {
  @JsonKey(fromJson: _intOrZero)
  final int routeId;

  /// 노선 번호 (예: "3-1", "602-1A").
  @JsonKey(fromJson: _stringOrEmpty)
  final String routeName;

  /// 노선 종점(방면) 이름.
  @JsonKey(fromJson: _stringOrNull)
  final String? routeDestName;

  /// 운행 상태 코드: RUN / PASS / STOP / WAIT 등.
  @JsonKey(fromJson: _stringOrNull)
  final String? flag;

  // ── 첫번째 차량 ──
  @JsonKey(fromJson: _intOrNull)
  final int? predictTime1;
  @JsonKey(fromJson: _intOrNull)
  final int? locationNo1;
  @JsonKey(fromJson: _stringOrNull)
  final String? plateNo1;
  @JsonKey(fromJson: _intOrNull)
  final int? lowPlate1;
  @JsonKey(fromJson: _intOrNull)
  final int? remainSeatCnt1;
  @JsonKey(fromJson: _intOrNull)
  final int? crowded1;

  // ── 두번째 차량 ──
  @JsonKey(fromJson: _intOrNull)
  final int? predictTime2;
  @JsonKey(fromJson: _intOrNull)
  final int? locationNo2;
  @JsonKey(fromJson: _stringOrNull)
  final String? plateNo2;
  @JsonKey(fromJson: _intOrNull)
  final int? lowPlate2;
  @JsonKey(fromJson: _intOrNull)
  final int? remainSeatCnt2;
  @JsonKey(fromJson: _intOrNull)
  final int? crowded2;

  const BusArrivalItemResponse({
    required this.routeId,
    required this.routeName,
    this.routeDestName,
    this.flag,
    this.predictTime1,
    this.locationNo1,
    this.plateNo1,
    this.lowPlate1,
    this.remainSeatCnt1,
    this.crowded1,
    this.predictTime2,
    this.locationNo2,
    this.plateNo2,
    this.lowPlate2,
    this.remainSeatCnt2,
    this.crowded2,
  });

  factory BusArrivalItemResponse.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BusArrivalItemResponseToJson(this);

  BusArrival toDomain() => BusArrival(
        routeId: routeId,
        routeName: routeName,
        destinationName: routeDestName,
        isRunning: flag == null || flag == 'RUN' || flag == 'PASS',
        first: _predictionFrom(
          predictMinutes: predictTime1,
          remainingStops: locationNo1,
          plateNo: plateNo1,
          lowPlate: lowPlate1,
          remainSeats: remainSeatCnt1,
          crowded: crowded1,
        ),
        second: _predictionFrom(
          predictMinutes: predictTime2,
          remainingStops: locationNo2,
          plateNo: plateNo2,
          lowPlate: lowPlate2,
          remainSeats: remainSeatCnt2,
          crowded: crowded2,
        ),
      );

  /// 도착 예정 시간이 없으면(차량 미배차) null 반환.
  static BusArrivalPrediction? _predictionFrom({
    required int? predictMinutes,
    required int? remainingStops,
    required String? plateNo,
    required int? lowPlate,
    required int? remainSeats,
    required int? crowded,
  }) {
    if (predictMinutes == null) return null;
    return BusArrivalPrediction(
      predictMinutes: predictMinutes,
      remainingStops: remainingStops,
      plateNo: plateNo,
      isLowFloor: lowPlate == 1,
      // -1 = 정보 없음 → null
      remainSeats: (remainSeats == null || remainSeats < 0) ? null : remainSeats,
      crowdLevel: crowded ?? 0,
    );
  }
}

/// `""`(빈 문자열)·null·숫자를 모두 안전하게 int? 로 변환.
int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

int _intOrZero(dynamic value) => _intOrNull(value) ?? 0;

/// `""`·null 을 null 로, 그 외는 trim 한 문자열로 변환.
String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

String _stringOrEmpty(dynamic value) => _stringOrNull(value) ?? '';
