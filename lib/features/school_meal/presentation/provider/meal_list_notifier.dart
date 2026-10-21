import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/core/utils/korea_time.dart';
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

// ── 날짜별 식사 목록 (식당 + 식사 유형별) ─────────────────────────────────────
// family 파라미터 date: "YYYY-MM-DD" 문자열(제공일), null 이면 오늘(KST).

@riverpod
class MealListNotifier extends _$MealListNotifier {
  /// 서버가 size 쿼리 파라미터를 최대 100으로 제한한다(초과 시 422).
  /// 따라서 한 페이지당 최대치(100)로 요청하고 전체 페이지를 순회해 누락을 방지한다.
  static const int _maxPageSize = 100;

  @override
  Future<List<Meal>> build({String? date}) async {
    final repo = ref.watch(mealRepositoryProvider);
    // 서버의 날짜 필터는 제공일(Meal.date) 기준 양 끝 포함(between)이다.
    // 따라서 하루만 조회하려면 start_date = end_date = 그 날짜로 보낸다.
    // date 가 null 이면 오늘(KST)로 해석한다.
    final day = date ?? DateFormatter.isoDate(KoreaTime.now());
    final items = <Meal>[];
    var page = 1;
    while (true) {
      final result = await repo.getMeals(
        page: page,
        size: _maxPageSize,
        startDate: day,
        endDate: day,
      );
      items.addAll(result.items);
      if (result.items.isEmpty || items.length >= result.total) break;
      page++;
    }
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(date: date));
  }
}
