import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/school_meal/data/data_source/meal_api.dart';
import 'package:handori/features/school_meal/data/dto/custom_page_response.dart';
import 'package:handori/features/school_meal/data/dto/meal_response.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';

/// 서버처럼 start_date~end_date(양 끝 포함)로 제공일을 거르는 가짜 API.
class _FakeApi implements MealApi {
  _FakeApi(this.byDate);
  final Map<String, int> byDate; // 날짜 -> 그 날 메뉴 개수
  final calls = <({int page, String? start, String? end})>[];

  @override
  Future<CustomPageResponse<MealResponse>> getMeals({
    int page = 1,
    int size = 50,
    String? startDate,
    String? endDate,
    String? restaurantName,
    String? mealType,
  }) async {
    calls.add((page: page, start: startDate, end: endDate));
    final all = [
      for (final e in byDate.entries)
        if (e.key.compareTo(startDate!) >= 0 && e.key.compareTo(endDate!) <= 0)
          for (var i = 0; i < e.value; i++) _meal('${e.key}#$i', e.key),
    ];
    final slice = all.skip((page - 1) * size).take(size).toList();
    return CustomPageResponse(
      status: 'success',
      meta: PaginationMeta(
        page: page,
        size: size,
        total: all.length,
        hasNext: page * size < all.length,
        hasPrev: page > 1,
      ),
      data: slice,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

MealResponse _meal(String key, String date) => MealResponse.fromJson({
  'id': key.hashCode,
  'restaurant_id': 1,
  'restaurant_name': 'r',
  'meal_type': 'lunch',
  'menu': [key],
  'registered_at': '${date}T01:00:00',
  'updated_at': '${date}T01:00:00',
});

void main() {
  setUp(() => KoreaTime.clock = () => DateTime.utc(2026, 10, 21, 3));
  tearDown(() => KoreaTime.clock = DateTime.now);

  ProviderContainer make(_FakeApi api) {
    final c = ProviderContainer(
      overrides: [mealApiProvider.overrideWithValue(api)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('오늘(date null)도 start=end=오늘로 요청하고 다른 날은 섞이지 않는다', () async {
    final api = _FakeApi({'2026-07-21': 2, '2026-10-21': 3, '2026-10-22': 4});
    final meals = await make(api).read(mealListNotifierProvider().future);
    expect(api.calls.single.start, '2026-10-21');
    expect(api.calls.single.end, '2026-10-21');
    expect(meals.length, 3);
  });

  test('다른 날도 start=end=그 날짜, 다음 날 메뉴가 섞이지 않는다', () async {
    final api = _FakeApi({'2026-10-21': 3, '2026-10-22': 4});
    final meals = await make(
      api,
    ).read(mealListNotifierProvider(date: '2026-10-22').future);
    expect(api.calls.single.start, '2026-10-22');
    expect(api.calls.single.end, '2026-10-22');
    expect(meals.length, 4);
  });

  test('has_next 가 있으면 모든 페이지를 모은다', () async {
    final api = _FakeApi({'2026-10-21': 250});
    final meals = await make(api).read(mealListNotifierProvider().future);
    expect(api.calls.map((c) => c.page), [1, 2, 3]);
    expect(meals.length, 250);
  });
}
