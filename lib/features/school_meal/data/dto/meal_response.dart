import 'package:json_annotation/json_annotation.dart';
import 'package:handori/features/school_meal/data/dto/restaurant_response.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';

part 'meal_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MealResponse {
  final int id;
  final List<String> menu;
  final MealType mealType;
  final DateTime registeredAt;
  final int restaurantId;
  final String restaurantName;
  final DateTime updatedAt;

  /// 메뉴 사진. 절대 주소 또는 학식 서버 기준 경로. 아직 서버에 없는 필드다.
  final String? imageUrl;

  const MealResponse({
    required this.id,
    required this.menu,
    required this.mealType,
    required this.registeredAt,
    required this.restaurantId,
    required this.restaurantName,
    required this.updatedAt,
    this.imageUrl,
  });

  factory MealResponse.fromJson(Map<String, dynamic> json) =>
      _$MealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MealResponseToJson(this);

  Meal toDomain() => Meal(
    id: id,
    menu: menu,
    mealType: mealType,
    registeredAt: registeredAt,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
    updatedAt: updatedAt,
    imageUrl: resolveMealImageUrl(imageUrl),
  );
}
