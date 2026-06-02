import 'package:json_annotation/json_annotation.dart';
import 'package:handori/features/bus/data/dto/bus_arrival_item_response.dart';
import 'package:handori/features/bus/domain/model/bus_arrival.dart';

part 'bus_arrival_response.g.dart';

/// 경기도 버스도착정보 응답 최상위 envelope.
/// 실제 데이터는 `response.msgBody.busArrivalList` 에 있다.
@JsonSerializable()
class BusArrivalResponse {
  final BusArrivalBody response;

  const BusArrivalResponse({required this.response});

  factory BusArrivalResponse.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BusArrivalResponseToJson(this);

  /// resultCode == 0 이면 정상. 그 외(4=데이터없음 등)는 도착 정보가 없다.
  bool get isSuccess => response.msgHeader.resultCode == 0;
  int get resultCode => response.msgHeader.resultCode;
  String get resultMessage => response.msgHeader.resultMessage;

  List<BusArrival> toDomain() =>
      (response.msgBody?.busArrivalList ?? const [])
          .map((e) => e.toDomain())
          .toList();
}

/// `response` 노드 — header / body.
@JsonSerializable()
class BusArrivalBody {
  final BusArrivalHeader msgHeader;
  final BusArrivalMsgBody? msgBody;

  const BusArrivalBody({required this.msgHeader, this.msgBody});

  factory BusArrivalBody.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalBodyFromJson(json);
  Map<String, dynamic> toJson() => _$BusArrivalBodyToJson(this);
}

/// 처리 결과 헤더.
@JsonSerializable()
class BusArrivalHeader {
  final int resultCode;
  final String resultMessage;
  final String? queryTime;

  const BusArrivalHeader({
    required this.resultCode,
    required this.resultMessage,
    this.queryTime,
  });

  factory BusArrivalHeader.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalHeaderFromJson(json);
  Map<String, dynamic> toJson() => _$BusArrivalHeaderToJson(this);
}

/// 도착 정보 목록을 담는 body.
@JsonSerializable()
class BusArrivalMsgBody {
  @JsonKey(fromJson: _busArrivalListFromJson)
  final List<BusArrivalItemResponse>? busArrivalList;

  const BusArrivalMsgBody({this.busArrivalList});

  factory BusArrivalMsgBody.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalMsgBodyFromJson(json);
  Map<String, dynamic> toJson() => _$BusArrivalMsgBodyToJson(this);
}

/// 공공데이터포털 API는 도착 버스가 1대면 배열(`[]`)이 아닌 단일 객체(`{}`)를
/// 반환한다. List/Map/null 을 모두 받아 항상 `List`로 정규화한다.
List<BusArrivalItemResponse>? _busArrivalListFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json
        .map((e) =>
            BusArrivalItemResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  if (json is Map<String, dynamic>) {
    return [BusArrivalItemResponse.fromJson(json)];
  }
  return null;
}
