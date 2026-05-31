// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationMeta _$PaginationMetaFromJson(Map<String, dynamic> json) =>
    PaginationMeta(
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
    );

Map<String, dynamic> _$PaginationMetaToJson(PaginationMeta instance) =>
    <String, dynamic>{
      'page': instance.page,
      'size': instance.size,
      'total': instance.total,
      'has_next': instance.hasNext,
      'has_prev': instance.hasPrev,
    };

CustomPageResponse<T> _$CustomPageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => CustomPageResponse<T>(
  status: json['status'] as String? ?? 'success',
  meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
  data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$CustomPageResponseToJson<T>(
  CustomPageResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'status': instance.status,
  'meta': instance.meta,
  'data': instance.data.map(toJsonT).toList(),
};
