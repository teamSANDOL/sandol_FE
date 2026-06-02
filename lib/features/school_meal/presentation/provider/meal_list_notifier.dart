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
  /// 서버가 size 쿼리 파라미터를 최대 100으로 제한한다(초과 시 422).
  /// 따라서 한 페이지당 최대치(100)로 요청하고 전체 페이지를 순회해 누락을 방지한다.
  static const int _maxPageSize = 100;

  @override
  Future<List<Meal>> build({String? date}) async {
    final repo = ref.watch(mealRepositoryProvider);
    // 서버의 날짜 필터는 [start_date, end_date) 반열린구간(end_date = 해당일 자정)이다.
    // 따라서 특정 하루(date)를 조회하려면 end_date 를 다음 날로 보내야
    // 그 날 낮에 등록된 식사가 포함된다. (date == null 이면 전체 최신)
    //
    // 단, '오늘'을 조회하는 경우에는 전날·주말에 미리 등록된 최신 식단(예: 가가 식당)이
    // 누락되지 않도록 챗봇과 동일하게 날짜 제한 없이(start/end = null) 최신 식단을 조회한다.
    final isToday = date == null || date == _today();
    final startDate = isToday ? null : date;
    final endDate = isToday ? null : _nextDay(date);
    final items = <Meal>[];
    var page = 1;
    while (true) {
      final result = await repo.getLatestMeals(
        page: page,
        size: _maxPageSize,
        startDate: startDate,
        endDate: endDate,
      );
      items.addAll(result.items);
      if (result.items.isEmpty || items.length >= result.total) break;
      page++;
    }
    return items;
  }

  /// "YYYY-MM-DD" 문자열의 다음 날짜를 같은 형식으로 반환한다.
  static String _nextDay(String date) {
    final next = DateTime.parse(date).add(const Duration(days: 1));
    final m = next.month.toString().padLeft(2, '0');
    final d = next.day.toString().padLeft(2, '0');
    return '${next.year}-$m-$d';
  }

  /// 오늘 날짜를 "YYYY-MM-DD" 형식으로 반환한다(호출부 date 형식과 동일).
  static String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(date: date));
  }
}
