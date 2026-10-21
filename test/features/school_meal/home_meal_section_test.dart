import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/common/component/sandol_chip.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';
import 'package:handori/features/school_meal/presentation/widget/meal_card.dart';

RestaurantMenu _menu(int id, String name, int itemCount) => RestaurantMenu(
  restaurant: Restaurant(id: id, name: name, establishmentType: ''),
  slots: [
    MenuSlot(
      mealType: MealType.lunch,
      label: '점심',
      timeRange: '',
      menu: [for (var i = 0; i < itemCount; i++) '$name 메뉴$i'],
    ),
  ],
);

void main() {
  // 점심 시간대(KST 12:00)로 고정해 어느 끼니가 보일지 시각에 의존하지 않게 한다.
  setUp(() => KoreaTime.clock = () => DateTime.utc(2026, 10, 6, 3));
  tearDown(() => KoreaTime.clock = DateTime.now);

  final menus = [_menu(1, 'A식당', 1), _menu(2, 'B식당', 6), _menu(3, 'C식당', 2)];

  late ProviderContainer container;
  var taps = 0;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    taps = 0;
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: HomeMealSection(menus: menus, onTap: () => taps++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  int? selectedId() => container.read(selectedRestaurantIdProvider);
  double pageHeight(WidgetTester tester) =>
      tester.getSize(find.byType(PageView)).height;
  double cardX(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;
  bool chipSelected(WidgetTester tester, String label) =>
      tester
          .widget<SandolChip>(find.widgetWithText(SandolChip, label))
          .selected;

  testWidgets('드래그 중 카드가 손가락 이동량만큼 따라온다', (tester) async {
    await pump(tester);
    final x0 = cardX(tester, 'A식당 메뉴0');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    // 터치 슬롭(첫 이동분 일부)은 소비되므로 이후 이동량(50)만큼은 반드시 따라온다.
    expect(x0 - cardX(tester, 'A식당 메뉴0'), inInclusiveRange(50, 80));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('절반 넘게 끌고 놓으면 다음 식당이 선택되고 칩이 갱신된다', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(PageView), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(selectedId(), 2);
    expect(chipSelected(tester, 'B식당'), isTrue);
    expect(chipSelected(tester, 'A식당'), isFalse);
  });

  testWidgets('짧게 끌고 놓으면 제자리로 돌아간다', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(PageView), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(chipSelected(tester, 'A식당'), isTrue);
    expect(cardX(tester, 'A식당 메뉴0'), closeTo(20 + 16, 40));
  });

  testWidgets('첫 페이지에서 오른쪽으로는 넘어가지 않는다', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(chipSelected(tester, 'A식당'), isTrue);
  });

  testWidgets('provider를 밖에서 바꾸면 해당 카드로 이동한다', (tester) async {
    await pump(tester);
    container.read(selectedRestaurantIdProvider.notifier).select(3);
    await tester.pumpAndSettle();
    expect(find.text('C식당 메뉴0'), findsOneWidget);
    expect(selectedId(), 3); // 이동 중 지나친 B로 덮어쓰이지 않는다
    expect(cardX(tester, 'C식당 메뉴0'), lessThan(412));
  });

  testWidgets('드래그 중 높이는 두 카드 높이 사이로 보간된다', (tester) async {
    await pump(tester);
    final hA = pageHeight(tester);
    container.read(selectedRestaurantIdProvider.notifier).select(2);
    await tester.pumpAndSettle();
    final hB = pageHeight(tester);
    expect(hB, greaterThan(hA));

    container.read(selectedRestaurantIdProvider.notifier).select(1);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    final mid = pageHeight(tester);
    expect(mid, greaterThan(hA));
    expect(mid, lessThan(hB));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pageHeight(tester), closeTo(hA, 0.5)); // 절반 미만이라 제자리
  });

  testWidgets('카드를 탭하면 선택을 확정하고 onTap을 부른다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('A식당 메뉴0'));
    expect(taps, 1);
    expect(selectedId(), 1);
  });
}
