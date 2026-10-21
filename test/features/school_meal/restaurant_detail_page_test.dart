import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
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

  Future<void> pump(WidgetTester tester) async {
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
          mealListNotifierProvider().overrideWith(() => _Meals(meals)),
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
        expect(find.text('TIP 가가식당'), findsOneWidget);
        expect(find.text('소고기 하이라이스'), findsOneWidget);
        expect(find.text('E동 레스토랑'), findsNothing);

        await tapTab(tester, '저녁');
        await tester.pumpAndSettle();
        expect(find.text('E동 레스토랑'), findsOneWidget);
        expect(find.text('김치찌개'), findsOneWidget);
        expect(find.text('TIP 가가식당'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('메뉴가 없는 끼니는 안내를 보여 준다', (tester) async {
        await pump(tester);
        await tapTab(tester, '조식');
        await tester.pumpAndSettle();
        expect(find.text('식당 0곳'), findsOneWidget);
        expect(find.text('등록된 식단이 없어요'), findsOneWidget);
      });
    });
  }
}
