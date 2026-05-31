import 'package:handori/features/school_meal/domain/model/restaurant.dart';

abstract class RestaurantRepository {
  /// 식당 목록 (이름/유형/캠퍼스 필터)
  Future<({List<Restaurant> items, int total})> getRestaurants({
    int page,
    int size,
    String? name,
    String? establishmentType,
    bool? isCampus,
  });

  /// 단일 식당 조회
  Future<Restaurant> getRestaurant(int restaurantId);
}
