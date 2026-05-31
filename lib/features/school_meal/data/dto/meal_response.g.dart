// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealResponse _$MealResponseFromJson(Map<String, dynamic> json) => MealResponse(
  id: (json['id'] as num).toInt(),
  menu: (json['menu'] as List<dynamic>).map((e) => e as String).toList(),
  mealType: $enumDecode(_$MealTypeEnumMap, json['meal_type']),
  registeredAt: DateTime.parse(json['registered_at'] as String),
  restaurantId: (json['restaurant_id'] as num).toInt(),
  restaurantName: json['restaurant_name'] as String,
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MealResponseToJson(MealResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'menu': instance.menu,
      'meal_type': _$MealTypeEnumMap[instance.mealType]!,
      'registered_at': instance.registeredAt.toIso8601String(),
      'restaurant_id': instance.restaurantId,
      'restaurant_name': instance.restaurantName,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.brunch: 'brunch',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
};
