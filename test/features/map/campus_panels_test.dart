import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handol/common/component/app_bottom_nav.dart';
import 'package:handol/features/empty_class/model/class_model.dart';
import 'package:handol/features/map/component/campus_panels.dart';

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

  // 갤럭시 기본 화면 밀도 450(폭 384dp)에서 6칸 줄이 넘치지 않는다.
  testWidgets('좁은 화면(384dp)에서도 시설 타일 줄이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(384, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        CampusHomePanel(
          controller: ScrollController(),
          onEmptyClass: () {},
          onShowAll: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
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
    var empty = 0, deselect = 0;
    Widget panel(bool expanded) => app(
      BuildingPanel(
        controller: ScrollController(),
        building: b,
        expanded: expanded,
        onDirections: () {},
        onDetail: () {},
        onEmptyClass: () => empty++,
        onDeselect: () => deselect++,
      ),
    );

    await tester.pumpWidget(panel(false));
    expect(tester.takeException(), isNull);
    expect(find.text('빈 강의실 12개'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
    expect(find.text('학습 공간'), findsOneWidget);
    await tester.tap(find.text('빈 강의실'));
    expect(empty, 1);
    expect(find.text('선택한 곳 다시 누르기'), findsOneWidget);
    await tester.tap(find.text('선택한 곳 다시 누르기'));
    expect(deselect, 1);

    await tester.pumpWidget(panel(true));
    expect(tester.takeException(), isNull);
    expect(find.text('상세보기'), findsNothing);
    expect(find.text('주요 시설'), findsOneWidget);
    expect(find.text('건물 소개 · 층별 안내는 준비중이에요'), findsOneWidget);
  });

  // 글꼴 2배(접근성 설정)에서 넘침·겹침이 없어야 한다.
  group('글꼴 2배', () {
    void bigText(WidgetTester tester) {
      phone(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    Rect labelRect(WidgetTester tester, String label) => Rect.fromPoints(
      tester.getTopLeft(find.text(label)),
      tester.getBottomRight(find.text(label)),
    );

    const b = EmptyClass(
      className: 'G동',
      classCount: '12',
      trafficIcon: 'assets/img/green.png',
      classIcons: 'assets/img/tukorea_Mechanical.png',
      classList: [],
      latitude: 37.34,
      longitude: 126.73,
    );

    for (final expanded in [false, true]) {
      testWidgets('건물 시트 머리 줄(상세보기: $expanded)이 넘치지 않는다', (tester) async {
        bigText(tester);
        await tester.pumpWidget(
          app(
            BuildingPanel(
              controller: ScrollController(),
              building: b,
              expanded: expanded,
              onDirections: () {},
              onDetail: () {},
              onEmptyClass: () {},
              onDeselect: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('G동'), findsOneWidget);
        expect(find.text('선택한 곳 다시 누르기'), findsOneWidget);
      });
    }

    testWidgets('시설 타일 라벨이 서로 겹치지 않는다', (tester) async {
      bigText(tester);
      await tester.pumpWidget(
        app(
          BuildingPanel(
            controller: ScrollController(),
            building: b,
            expanded: false,
            onDirections: () {},
            onDetail: () {},
            onEmptyClass: () {},
            onDeselect: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final a = labelRect(tester, '빈 강의실');
      final c = labelRect(tester, '스터디룸');
      expect(a.overlaps(c), isFalse);

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
      expect(
        labelRect(tester, '편의점').overlaps(labelRect(tester, '자판기')),
        isFalse,
      );
    });
  });
}
