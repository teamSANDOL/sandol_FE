// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_arrival_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusArrivalResponse _$BusArrivalResponseFromJson(Map<String, dynamic> json) =>
    BusArrivalResponse(
      response: BusArrivalBody.fromJson(
        json['response'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BusArrivalResponseToJson(BusArrivalResponse instance) =>
    <String, dynamic>{'response': instance.response};

BusArrivalBody _$BusArrivalBodyFromJson(Map<String, dynamic> json) =>
    BusArrivalBody(
      msgHeader: BusArrivalHeader.fromJson(
        json['msgHeader'] as Map<String, dynamic>,
      ),
      msgBody:
          json['msgBody'] == null
              ? null
              : BusArrivalMsgBody.fromJson(
                json['msgBody'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$BusArrivalBodyToJson(BusArrivalBody instance) =>
    <String, dynamic>{
      'msgHeader': instance.msgHeader,
      'msgBody': instance.msgBody,
    };

BusArrivalHeader _$BusArrivalHeaderFromJson(Map<String, dynamic> json) =>
    BusArrivalHeader(
      resultCode: (json['resultCode'] as num).toInt(),
      resultMessage: json['resultMessage'] as String,
      queryTime: json['queryTime'] as String?,
    );

Map<String, dynamic> _$BusArrivalHeaderToJson(BusArrivalHeader instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMessage': instance.resultMessage,
      'queryTime': instance.queryTime,
    };

BusArrivalMsgBody _$BusArrivalMsgBodyFromJson(Map<String, dynamic> json) =>
    BusArrivalMsgBody(
      busArrivalList: _busArrivalListFromJson(json['busArrivalList']),
    );

Map<String, dynamic> _$BusArrivalMsgBodyToJson(BusArrivalMsgBody instance) =>
    <String, dynamic>{'busArrivalList': instance.busArrivalList};
