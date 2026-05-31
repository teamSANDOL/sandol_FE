import 'package:handori/features/school_meal/data/data_source/restaurant_api.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/domain/repository/restaurant_repository.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantApi _api;

  const RestaurantRepositoryImpl(this._api);

  @override
  Future<({List<Restaurant> items, int total})> getRestaurants({
    int page = 1,
    int size = 50,
    String? name,
    String? establishmentType,
    bool? isCampus,
  }) async {
    final response = await _api.getRestaurants(
      page: page,
      size: size,
      name: name,
      establishmentType: establishmentType,
      isCampus: isCampus,
    );
    return (
      items: response.data.map((e) => e.toDomain()).toList(),
      total: response.meta.total,
    );
  }

  @override
  Future<Restaurant> getRestaurant(int restaurantId) async {
    final response = await _api.getRestaurant(restaurantId);
    return response.data.toDomain();
  }
}
