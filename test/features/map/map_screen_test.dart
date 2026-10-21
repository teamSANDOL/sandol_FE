import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/map/component/empty_class_panel.dart';
import 'package:handori/features/map/component/tuk_world_panel.dart';
import 'package:handori/features/map/presentation/provider/tuk_world_provider.dart';
import 'package:handori/features/map/screen/map_screen.dart';

void main() {
  const e = EmptyClass(
    className: 'E동',
    classCount: '1',
    trafficIcon: 'assets/img/green.png',
    classIcons: 'assets/img/tukorea_computer.png',
    classList: ['E101'],
    latitude: 37.3397,
    longitude: 126.735,
    allRooms: ['E101', 'E102'],
  );

  Widget host(ProviderContainer container) => UncontrolledProviderScope(
    container: container,
    // 네이버 지도는 플랫폼 뷰라 테스트에서 그릴 수 없다.
    child: const MaterialApp(home: MapScreen(mapOverride: SizedBox.expand())),
  );

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [
        emptyClassesProvider.overrideWith((ref) async => [e]),
        tukWorldPlacesProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('첫 시트 → 빈 강의실 현황 → 뒤로', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(make()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('장소를 검색하세요'), findsOneWidget);
    expect(find.text('지금 많이 찾는 시설'), findsOneWidget);

    await tester.tap(find.text('빈 강의실'));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyClassPanel), findsOneWidget);
    expect(find.text('E102'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('지금 많이 찾는 시설'), findsOneWidget);
  });

  testWidgets('홈에서 넘긴 건물은 빈 강의실 현황으로 연다', (tester) async {
    phone(tester);
    final c = make();
    c.read(emptyClassFocusControllerProvider.notifier).request('E동');
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyClassPanel), findsOneWidget);
    expect(c.read(emptyClassFocusControllerProvider), isNull);
    // 뒤로가면 그 건물 시트
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('빈 강의실 1개'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
  });

  testWidgets('TUK 월드 탭과 장소 검색', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(make()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TUK 월드'));
    await tester.pumpAndSettle();
    expect(find.byType(TukWorldPanel), findsOneWidget);

    await tester.tap(find.text('교내시설'));
    await tester.pumpAndSettle();
    expect(find.text('지금 많이 찾는 시설'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'E');
    await tester.pumpAndSettle();
    await tester.tap(find.text('E동').last);
    await tester.pumpAndSettle();
    expect(find.text('학습 공간'), findsOneWidget);
  });
}
