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
  /// 서버가 size 쿼리 파라미터를 최대 100으로 제한한다(초과 시 422).
  /// 따라서 한 페이지당 최대치(100)로 요청하고 전체 페이지를 순회해 누락을 방지한다.
  static const int _maxPageSize = 100;

  @override
  Future<List<Restaurant>> build() async {
    final repo = ref.watch(restaurantRepositoryProvider);
    final items = <Restaurant>[];
    var page = 1;
    while (true) {
      final result = await repo.getRestaurants(page: page, size: _maxPageSize);
      items.addAll(result.items);
      if (result.items.isEmpty || items.length >= result.total) break;
      page++;
    }
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
