import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/domain/model/class_period.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/map/component/empty_class_panel.dart';

EmptyClass _b(String name, List<String> empty, List<String> all) => EmptyClass(
  className: name,
  classCount: '${empty.length}',
  trafficIcon: 'assets/img/green.png',
  classIcons: 'assets/img/tino6.png',
  classList: empty,
  latitude: null,
  longitude: null,
  totalCount: all.length,
  allRooms: all,
);

void main() {
  final items = [
    _b('A동', ['101호', '201호'], ['101호', '102호', '201호']),
    _b('E동', ['301호'], ['301호', '302호']),
  ];

  Widget host({
    Future<List<EmptyClass>> Function()? load,
    ValueChanged<EmptyClass>? onTap,
  }) => ProviderScope(
    overrides: [
      emptyClassesProvider.overrideWith((ref) => (load ?? () async => items)()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: EmptyClassPanel(
          controller: ScrollController(),
          onBack: () {},
          onBuildingTap: onTap ?? (_) {},
        ),
      ),
    ),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('전체 목록이 있으면 빈 호실 외는 수업예정, 없으면 빈 호실만', () {
    expect(roomsWithStatus(items.first), [
      ('101호', RoomStatus.empty),
      ('102호', RoomStatus.busy),
      ('201호', RoomStatus.empty),
    ]);
    expect(roomsWithStatus(_b('B동', ['101호'], [])), [
      ('101호', RoomStatus.empty),
    ]);
  });

  testWidgets('건물별 호실 상태와 합계를 그린다', (tester) async {
    phone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('빈 강의실 현황'), findsOneWidget);
    expect(find.text('총 3개'), findsOneWidget);
    expect(find.text('A동'), findsOneWidget);
    expect(find.text('2개'), findsOneWidget);
    expect(find.text('1층'), findsOneWidget);
    // 호실 칩 + 범례 한 개씩
    expect(find.text('비어있음'), findsNWidgets(3 + 1));
    expect(find.text('수업예정'), findsNWidgets(2 + 1));
  });

  testWidgets('강의실 검색은 호실을 걸러낸다', (tester) async {
    phone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '302');
    await tester.pumpAndSettle();
    expect(find.text('302호'), findsOneWidget);
    expect(find.text('301호'), findsNothing);
    expect(find.text('A동'), findsNothing);

    await tester.enterText(find.byType(TextField), '없는방');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('교시를 고르면 조회 구간이 그 교시로 바뀐다', (tester) async {
    phone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('교시'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3교시').last);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EmptyClassPanel)),
    );
    final q = container.read(classroomQueryControllerProvider);
    expect((start: q.startMinutes, end: q.endMinutes), classPeriods[2]);
    expect(find.text('3교시'), findsOneWidget);
    expect(find.textContaining('11:30 ~ 12:20 동안'), findsOneWidget);
  });

  testWidgets('건물 머리를 누르면 그 건물을 넘긴다', (tester) async {
    phone(tester);
    EmptyClass? tapped;
    await tester.pumpWidget(host(onTap: (b) => tapped = b));
    await tester.pumpAndSettle();

    await tester.tap(find.text('E동'));
    expect(tapped?.className, 'E동');
  });

  testWidgets('불러오기 실패는 재시도 화면', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(load: () async => throw Exception('x')));
    await tester.pumpAndSettle();
    expect(find.text('빈 강의실 정보를 불러오지 못했어요'), findsOneWidget);
  });
}
