import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/school_meal/data/dto/base_response.dart';
import 'package:handori/features/school_meal/data/dto/custom_page_response.dart';
import 'package:handori/features/school_meal/data/dto/restaurant_response.dart';

part 'restaurant_api.g.dart';

@RestApi()
abstract class RestaurantApi {
  factory RestaurantApi(Dio dio, {String? baseUrl}) = _RestaurantApi;

  @GET('/meal/restaurants/')
  Future<CustomPageResponse<RestaurantResponse>> getRestaurants({
    @Query('page') int page = 1,
    @Query('size') int size = 50,
    @Query('name') String? name,
    @Query('establishment_type') String? establishmentType,
    @Query('is_campus') bool? isCampus,
  });

  @GET('/meal/restaurants/{restaurant_id}')
  Future<BaseResponse<RestaurantResponse>> getRestaurant(
    @Path('restaurant_id') int restaurantId,
  );
}
