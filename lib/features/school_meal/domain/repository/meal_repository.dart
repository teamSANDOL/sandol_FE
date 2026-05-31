import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';

abstract class MealRepository {
  /// 전체 식사 목록 (기간/식당명/유형 필터)
  Future<({List<Meal> items, int total})> getMeals({
    int page,
    int size,
    String? startDate,
    String? endDate,
    String? restaurantName,
    MealType? mealType,
  });

  /// 식당별 + 식사 유형별 최신 식사 1건씩
  Future<({List<Meal> items, int total})> getLatestMeals({
    int page,
    int size,
    String? startDate,
    String? endDate,
    String? restaurantName,
    MealType? mealType,
  });

  /// 단일 식사 조회
  Future<Meal> getMeal(int mealId);

  /// 특정 식당의 식사 유형별 최신 식사
  Future<({List<Meal> items, int total})> getLatestMealsByRestaurant({
    required int restaurantId,
    int page,
    int size,
  });

  /// 특정 식당의 식사 목록 (기간 필터)
  Future<({List<Meal> items, int total})> getMealsByRestaurant({
    required int restaurantId,
    int page,
    int size,
    String? startDate,
    String? endDate,
  });
}
