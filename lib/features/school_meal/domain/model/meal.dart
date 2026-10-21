import 'package:handori/features/school_meal/domain/model/meal_type.dart';

/// 개별 식사(식당 + 식사 유형 단위) 도메인 모델
class Meal {
  final int id;
  final List<String> menu;
  final MealType mealType;
  final DateTime registeredAt;
  final int restaurantId;
  final String restaurantName;
  final DateTime updatedAt;

  /// 이 끼니 메뉴 사진 주소(절대 주소로 풀린 값). 서버 `image_url`이 없으면 null.
  /// 있으면 식당 사진보다 먼저 보여 준다.
  final String? imageUrl;

  const Meal({
    required this.id,
    required this.menu,
    required this.mealType,
    required this.registeredAt,
    required this.restaurantId,
    required this.restaurantName,
    required this.updatedAt,
    this.imageUrl,
  });
}
