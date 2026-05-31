import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/meal_dio_provider.dart';
import 'package:handori/features/school_meal/data/data_source/meal_api.dart';
import 'package:handori/features/school_meal/data/repository/meal_repository_impl.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/repository/meal_repository.dart';

part 'meal_list_notifier.g.dart';

// ── API / Repository ─────────────────────────────────────────────────────────

@riverpod
MealApi mealApi(Ref ref) {
  final dio = ref.watch(mealDioProvider);
  return MealApi(dio);
}

@riverpod
MealRepository mealRepository(Ref ref) {
  final api = ref.watch(mealApiProvider);
  return MealRepositoryImpl(api);
}

// ── 최신 식사 목록 (식당 + 식사 유형별) ───────────────────────────────────────
// family 파라미터 date: "YYYY-MM-DD" 문자열, null 이면 전체 최신.

@riverpod
class MealListNotifier extends _$MealListNotifier {
  static const int _size = 100;

  @override
  Future<List<Meal>> build({String? date}) async {
    final repo = ref.watch(mealRepositoryProvider);
    final result = await repo.getLatestMeals(
      size: _size,
      startDate: date,
      endDate: date,
    );
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(date: date));
  }
}
