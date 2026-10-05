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
import 'package:handori/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';

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

  testWidgets('식당 칩 · 이름 · 끼니별 메뉴가 두 열로 그려진다', (tester) async {
    await pump(tester);
    // 칩 + 제목
    expect(find.text('TIP 가가식당'), findsNWidgets(2));
    expect(find.text('TIP 1층'), findsOneWidget); // 위치 폴백
    expect(find.text('점심'), findsOneWidget);
    expect(find.text('소고기 하이라이스'), findsOneWidget);
    expect(find.text('파채콩나물무침'), findsOneWidget);
    // 등록 안 된 끼니
    expect(find.text('아직 등록된 메뉴가 없어요'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('칩을 누르면 식당이 바뀌고 전역 선택이 갱신된다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('E동 레스토랑'));
    await tester.pumpAndSettle();

    expect(find.text('E동 레스토랑'), findsNWidgets(2));
    expect(find.text('김치찌개'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RestaurantDetailPage)),
    );
    expect(container.read(selectedRestaurantIdProvider), 2);
  });
}
