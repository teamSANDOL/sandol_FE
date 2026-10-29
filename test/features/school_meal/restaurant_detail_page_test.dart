import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/page/restaurant_detail_page.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';

class _Restaurants extends RestaurantListNotifier {
  _Restaurants(this.items);
  final List<Restaurant> items;
  @override
  Future<List<Restaurant>> build() async => items;
}

class _Meals extends MealListNotifier {
  _Meals(this.items);
  final List<Meal> items;
  @override
  Future<List<Meal>> build({String? date}) async => items;
}

void main() {
  const gaga = Restaurant(id: 1, name: 'TIP 가가식당', establishmentType: '');
  const edong = Restaurant(id: 2, name: 'E동 레스토랑', establishmentType: '');
  final meals = [
    Meal(
      id: 1,
      restaurantId: 1,
      mealType: MealType.lunch,
      menu: const ['소고기 하이라이스', '소떡소떡', '고추지무침', '순두부 백탕', '파채콩나물무침'],
      restaurantName: gaga.name,
      registeredAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
    ),
    Meal(
      id: 2,
      restaurantId: 2,
      mealType: MealType.dinner,
      menu: const ['김치찌개'],
      restaurantName: edong.name,
      registeredAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<Meal>? todayMeals,
    List<Meal> otherDayMeals = const [],
  }) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/meal',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => RootShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const Text('home')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/meal',
                  builder: (_, _) => const RestaurantDetailPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantListNotifierProvider.overrideWith(
            () => _Restaurants([gaga, edong]),
          ),
          mealListNotifierProvider().overrideWith(
            () => _Meals(todayMeals ?? meals),
          ),
          mealListNotifierProvider(
            date: '2026-10-07',
          ).overrideWith(() => _Meals(otherDayMeals)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  // 선택한 끼니는 탭과 목록 제목에 모두 보이므로 탭(앞쪽)을 누른다.
  Future<void> tapTab(WidgetTester tester, String label) =>
      tester.tap(find.textContaining(label).first);

  // 지금 끼니가 기본 선택이므로 조식·점심·저녁 시각 모두에서 검사한다(2026-10-06 KST).
  for (final (name, hour) in [('조식', 8), ('점심', 12), ('저녁', 19)]) {
    group('$name 시각', () {
      setUp(
        () =>
            KoreaTime.clock =
                () =>
                    DateTime.utc(2026, 10, 6, hour).subtract(KoreaTime.offset),
      );
      tearDown(() => KoreaTime.clock = DateTime.now);

      testWidgets('끼니 탭을 누르면 그 끼니를 내는 식당 카드만 보인다', (tester) async {
        await pump(tester);
        // 요일 스트립 7칸 + 끼니 탭
        expect(find.textContaining('월\n'), findsOneWidget);
        expect(find.textContaining('일\n'), findsOneWidget);
        expect(find.text('인기순'), findsOneWidget);

        await tapTab(tester, '점심');
        await tester.pumpAndSettle();
        expect(find.text('식당 1곳'), findsOneWidget);
        expect(find.text('TIP 가가식당'.keepAll), findsOneWidget);
        expect(find.text('소고기 하이라이스'.keepAll), findsOneWidget);
        expect(find.text('E동 레스토랑'.keepAll), findsNothing);

        await tapTab(tester, '저녁');
        await tester.pumpAndSettle();
        expect(find.text('E동 레스토랑'.keepAll), findsOneWidget);
        expect(find.text('김치찌개'.keepAll), findsOneWidget);
        expect(find.text('TIP 가가식당'.keepAll), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('메뉴가 없는 끼니는 안내를 보여 준다', (tester) async {
        await pump(tester);
        await tapTab(tester, '조식');
        await tester.pumpAndSettle();
        expect(find.text('식당 0곳'), findsOneWidget);
        expect(find.text('등록된 식단이 없어요'.keepAll), findsOneWidget);
      });
    });
  }

  group('기본 끼니 선택', () {
    void at(int hour) =>
        KoreaTime.clock =
            () => DateTime.utc(2026, 10, 6, hour).subtract(KoreaTime.offset);
    tearDown(() => KoreaTime.clock = DateTime.now);

    final breakfast = Meal(
      id: 3,
      restaurantId: 1,
      mealType: MealType.breakfast,
      menu: const ['토스트'],
      restaurantName: gaga.name,
      registeredAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
    );

    testWidgets('05:00 조식 없음 -> 점심 선택, 조식에 NOW', (tester) async {
      at(5);
      await pump(tester);
      expect(find.text('조식 • NOW'), findsOneWidget);
      expect(find.text('소고기 하이라이스'.keepAll), findsOneWidget);
      expect(find.text('식당 1곳'), findsOneWidget);
    });

    testWidgets('08:00 조식 있음 -> 조식', (tester) async {
      at(8);
      await pump(tester, todayMeals: [breakfast, ...meals]);
      expect(find.text('토스트'.keepAll), findsOneWidget);
      expect(find.text('소고기 하이라이스'.keepAll), findsNothing);
    });

    testWidgets('오늘이 아닌 날짜는 메뉴 있는 첫 끼니', (tester) async {
      at(8);
      await pump(
        tester,
        otherDayMeals: [meals[1]], // 저녁만
      );
      await tester.tap(find.textContaining('수\n'));
      await tester.pumpAndSettle();
      expect(find.text('김치찌개'.keepAll), findsOneWidget);
      expect(find.text('조식 • NOW'), findsNothing);
    });

    testWidgets('직접 고른 끼니는 유지, 날짜를 바꾸면 규칙 재적용', (tester) async {
      at(5);
      await pump(tester);
      await tapTab(tester, '조식');
      await tester.pumpAndSettle();
      expect(find.text('식당 0곳'), findsOneWidget);
      await tester.tap(find.textContaining('수\n'));
      await tester.pumpAndSettle();
      expect(find.text('식당 0곳'), findsOneWidget); // 수요일 데이터 없음 -> 현재 끼니(조식)
    });
  });
}
