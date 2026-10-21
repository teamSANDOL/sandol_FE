import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/common/component/app_bottom_nav.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/map/component/campus_panels.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('하단바 5번째 탭은 맵', (tester) async {
    await tester.pumpWidget(app(AppBottomNav(currentIndex: 4, onTap: (_) {})));
    expect(find.text('맵'), findsOneWidget);
    expect(find.text('빈 강의실'), findsNothing);
  });

  testWidgets('첫 시트: 빈 강의실 · 전체보기는 동작, 나머지는 준비중', (tester) async {
    phone(tester);
    var empty = 0, all = 0;
    await tester.pumpWidget(
      app(
        CampusHomePanel(
          controller: ScrollController(),
          onEmptyClass: () => empty++,
          onShowAll: () => all++,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('지금 많이 찾는 시설'), findsOneWidget);

    await tester.tap(find.text('빈 강의실'));
    await tester.tap(find.text('전체보기'));
    expect((empty, all), (1, 1));

    await tester.tap(find.text('카페'));
    await tester.pump();
    expect(find.text('준비중입니다'), findsOneWidget);
  });

  testWidgets('필터 시트의 두 줄 시설', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      app(
        FacilityFilterPanel(
          controller: ScrollController(),
          onClose: () {},
          onEmptyClass: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final label in [
      '전체',
      '빈 강의실',
      '식당',
      '카페',
      '프린트',
      '스터디룸',
      '편의점',
      '자판기',
      '휴게공간',
      '기타',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('건물 시트와 상세보기', (tester) async {
    phone(tester);
    const b = EmptyClass(
      className: 'G동',
      classCount: '12',
      trafficIcon: 'assets/img/green.png',
      classIcons: 'assets/img/tukorea_Mechanical.png',
      classList: [],
      latitude: 37.34,
      longitude: 126.73,
    );
    var empty = 0;
    Widget panel(bool expanded) => app(
      BuildingPanel(
        controller: ScrollController(),
        building: b,
        expanded: expanded,
        onDirections: () {},
        onDetail: () {},
        onEmptyClass: () => empty++,
      ),
    );

    await tester.pumpWidget(panel(false));
    expect(tester.takeException(), isNull);
    expect(find.text('빈 강의실 12개'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
    expect(find.text('학습 공간'), findsOneWidget);
    await tester.tap(find.text('빈 강의실'));
    expect(empty, 1);

    await tester.pumpWidget(panel(true));
    expect(tester.takeException(), isNull);
    expect(find.text('상세보기'), findsNothing);
    expect(find.text('주요 시설'), findsOneWidget);
    expect(find.text('건물 소개 · 층별 안내는 준비중이에요'), findsOneWidget);
  });
}
