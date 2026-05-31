import 'package:json_annotation/json_annotation.dart';
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

  const MealResponse({
    required this.id,
    required this.menu,
    required this.mealType,
    required this.registeredAt,
    required this.restaurantId,
    required this.restaurantName,
    required this.updatedAt,
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
      );
}
