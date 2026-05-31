import 'package:handori/features/school_meal/data/data_source/meal_api.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/repository/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  final MealApi _api;

  const MealRepositoryImpl(this._api);

  @override
  Future<({List<Meal> items, int total})> getMeals({
    int page = 1,
    int size = 50,
    String? startDate,
    String? endDate,
    String? restaurantName,
    MealType? mealType,
  }) async {
    final response = await _api.getMeals(
      page: page,
      size: size,
      startDate: startDate,
      endDate: endDate,
      restaurantName: restaurantName,
      mealType: mealType?.name,
    );
    return (
      items: response.data.map((e) => e.toDomain()).toList(),
      total: response.meta.total,
    );
  }

  @override
  Future<({List<Meal> items, int total})> getLatestMeals({
    int page = 1,
    int size = 50,
    String? startDate,
    String? endDate,
    String? restaurantName,
    MealType? mealType,
  }) async {
    final response = await _api.getLatestMeals(
      page: page,
      size: size,
      startDate: startDate,
      endDate: endDate,
      restaurantName: restaurantName,
      mealType: mealType?.name,
    );
    return (
      items: response.data.map((e) => e.toDomain()).toList(),
      total: response.meta.total,
    );
  }

  @override
  Future<Meal> getMeal(int mealId) async {
    final response = await _api.getMeal(mealId);
    return response.data.toDomain();
  }

  @override
  Future<({List<Meal> items, int total})> getLatestMealsByRestaurant({
    required int restaurantId,
    int page = 1,
    int size = 50,
  }) async {
    final response = await _api.getLatestMealsByRestaurant(
      restaurantId,
      page: page,
      size: size,
    );
    return (
      items: response.data.map((e) => e.toDomain()).toList(),
      total: response.meta.total,
    );
  }

  @override
  Future<({List<Meal> items, int total})> getMealsByRestaurant({
    required int restaurantId,
    int page = 1,
    int size = 50,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _api.getMealsByRestaurant(
      restaurantId,
      page: page,
      size: size,
      startDate: startDate,
      endDate: endDate,
    );
    return (
      items: response.data.map((e) => e.toDomain()).toList(),
      total: response.meta.total,
    );
  }
}
