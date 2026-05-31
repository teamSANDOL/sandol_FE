import 'package:json_annotation/json_annotation.dart';

part 'custom_page_response.g.dart';

/// 페이지네이션 메타데이터 (`meta` 객체)
@JsonSerializable(fieldRename: FieldRename.snake)
class PaginationMeta {
  final int page;
  final int size;
  final int total;
  final bool hasNext;
  final bool hasPrev;

  const PaginationMeta({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}

/// `{ status, meta: {...}, data: [...] }` 형태의 공통 페이징 응답 래퍼
@JsonSerializable(genericArgumentFactories: true)
class CustomPageResponse<T> {
  @JsonKey(defaultValue: 'success')
  final String status;
  final PaginationMeta meta;
  final List<T> data;

  const CustomPageResponse({
    required this.status,
    required this.meta,
    required this.data,
  });

  factory CustomPageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$CustomPageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$CustomPageResponseToJson(this, toJsonT);
}
