import 'package:json_annotation/json_annotation.dart';

part 'base_response.g.dart';

/// `{ status, meta, data: {...} }` 형태의 단건 응답 래퍼 (BaseSchema[T])
@JsonSerializable(genericArgumentFactories: true)
class BaseResponse<T> {
  @JsonKey(defaultValue: 'success')
  final String status;
  final T data;

  const BaseResponse({required this.status, required this.data});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$BaseResponseToJson(this, toJsonT);
}
