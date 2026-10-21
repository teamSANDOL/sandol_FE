import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
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

  testWidgets('끼니 탭을 누르면 그 끼니를 내는 식당 카드만 보인다', (tester) async {
    await pump(tester);
    // 요일 스트립 7칸 + 끼니 탭
    expect(find.textContaining('월\n'), findsOneWidget);
    expect(find.textContaining('일\n'), findsOneWidget);
    expect(find.text('인기순'), findsOneWidget);

    await tester.tap(find.textContaining('점심'));
    await tester.pumpAndSettle();
    expect(find.text('식당 1곳'), findsOneWidget);
    expect(find.text('TIP 가가식당'), findsOneWidget);
    expect(find.text('소고기 하이라이스'), findsOneWidget);
    expect(find.text('E동 레스토랑'), findsNothing);

    await tester.tap(find.textContaining('저녁'));
    await tester.pumpAndSettle();
    expect(find.text('E동 레스토랑'), findsOneWidget);
    expect(find.text('김치찌개'), findsOneWidget);
    expect(find.text('TIP 가가식당'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('메뉴가 없는 끼니는 안내를 보여 준다', (tester) async {
    await pump(tester);
    await tester.tap(find.textContaining('조식'));
    await tester.pumpAndSettle();
    expect(find.text('식당 0곳'), findsOneWidget);
    expect(find.text('등록된 식단이 없어요'), findsOneWidget);
  });
}
