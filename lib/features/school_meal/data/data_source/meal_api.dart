import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/school_meal/data/dto/base_response.dart';
import 'package:handori/features/school_meal/data/dto/custom_page_response.dart';
import 'package:handori/features/school_meal/data/dto/meal_response.dart';

part 'meal_api.g.dart';

@RestApi()
abstract class MealApi {
  factory MealApi(Dio dio, {String? baseUrl}) = _MealApi;

  @GET('/meal/meals')
  Future<CustomPageResponse<MealResponse>> getMeals({
    @Query('page') int page = 1,
    @Query('size') int size = 50,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('restaurant_name') String? restaurantName,
    @Query('meal_type') String? mealType,
  });

  @GET('/meal/meals/latest')
  Future<CustomPageResponse<MealResponse>> getLatestMeals({
    @Query('page') int page = 1,
    @Query('size') int size = 50,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('restaurant_name') String? restaurantName,
    @Query('meal_type') String? mealType,
  });

  @GET('/meal/meals/{meal_id}')
  Future<BaseResponse<MealResponse>> getMeal(@Path('meal_id') int mealId);

  @GET('/meal/meals/restaurant/{restaurant_id}/latest')
  Future<CustomPageResponse<MealResponse>> getLatestMealsByRestaurant(
    @Path('restaurant_id') int restaurantId, {
    @Query('page') int page = 1,
    @Query('size') int size = 50,
  });

  @GET('/meal/meals/restaurant/{restaurant_id}')
  Future<CustomPageResponse<MealResponse>> getMealsByRestaurant(
    @Path('restaurant_id') int restaurantId, {
    @Query('page') int page = 1,
    @Query('size') int size = 50,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  });
}
