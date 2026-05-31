import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/meal_dio_provider.dart';
import 'package:handori/features/school_meal/data/data_source/restaurant_api.dart';
import 'package:handori/features/school_meal/data/repository/restaurant_repository_impl.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/domain/repository/restaurant_repository.dart';

part 'restaurant_list_notifier.g.dart';

// ── API / Repository ─────────────────────────────────────────────────────────

@riverpod
RestaurantApi restaurantApi(Ref ref) {
  final dio = ref.watch(mealDioProvider);
  return RestaurantApi(dio);
}

@riverpod
RestaurantRepository restaurantRepository(Ref ref) {
  final api = ref.watch(restaurantApiProvider);
  return RestaurantRepositoryImpl(api);
}

// ── 식당 목록 (탭 바용) ────────────────────────────────────────────────────────

@riverpod
class RestaurantListNotifier extends _$RestaurantListNotifier {
  static const int _size = 100;

  @override
  Future<List<Restaurant>> build() async {
    final repo = ref.watch(restaurantRepositoryProvider);
    final result = await repo.getRestaurants(size: _size);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
