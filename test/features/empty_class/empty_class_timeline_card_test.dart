import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/component/empty_class_card.dart';
import 'package:handori/features/empty_class/domain/model/nearby_empty_class.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

EmptyClass _b(String name, int n, {double? lat, double? lng}) => EmptyClass(
      className: name,
      classCount: '$n',
      trafficIcon: 'assets/img/green.png',
      classIcons: 'assets/img/tino6.png',
      classList: List.generate(n, (i) => '${100 + i}호'),
      latitude: lat,
      longitude: lng,
      totalCount: 30,
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Widget host(List<NearbyEmptyClass> items, {ValueChanged<String>? onTap}) =>
      ProviderScope(
        overrides: [
          userLocationProvider.overrideWith((ref) async => null),
          nearbyEmptyClassesProvider.overrideWith((ref) async => items),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: EmptyClassTimelineCard(maxItems: 3, onBuildingTap: onTap),
            ),
          ),
        ),
      );

  testWidgets('건물 목록과 요약이 오버플로 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host([
      NearbyEmptyClass(building: _b('E동', 13, lat: 37.3397, lng: 126.7350), distanceMeters: 120),
      NearbyEmptyClass(building: _b('산융', 24, lat: 37.3387, lng: 126.7345), distanceMeters: 410),
      NearbyEmptyClass(building: _b('TIP', 15)),
      NearbyEmptyClass(building: _b('중앙', 0)),
    ]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('E동'), findsOneWidget);
    expect(find.text('산융'), findsOneWidget);
    expect(find.text('TIP'), findsOneWidget);
    // 0곳인 건물은 홈 목록에서 숨긴다
    expect(find.text('중앙'), findsNothing);
    expect(find.text('도보 2분'), findsOneWidget);
    expect(find.textContaining('가까움'), findsNothing);
    // 호실 칩: 앞 4개 + 나머지 개수
    expect(find.text('100호'), findsNWidgets(3));
    expect(find.text('+9'), findsOneWidget); // E동 13곳 → 4개 미리보기 + 9
    expect(find.text('+20'), findsOneWidget); // 산융 24곳
    expect(find.text('도보 6분'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.textContaining('내 위치 정렬', findRichText: true), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget); // 정렬 설정 아이콘
  });

  testWidgets('설정 아이콘 → 정렬 시트 → 내 순서 선택 시 햄버거 목록', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host([
      NearbyEmptyClass(building: _b('E동', 3)),
      NearbyEmptyClass(building: _b('산융', 2)),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SvgPicture));
    await tester.pumpAndSettle();
    expect(find.text('정렬 설정'), findsOneWidget);
    expect(find.text('빈 강의실 많은 순'), findsOneWidget);

    await tester.tap(find.text('내 순서 정렬'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_handle_rounded), findsWidgets);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 폭에서도 오버플로가 없다', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host([
      NearbyEmptyClass(building: _b('E동', 13), distanceMeters: 1500),
    ]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('건물 행을 누르면 건물명을 넘긴다', (tester) async {
    String? tapped;
    await tester.pumpWidget(host(
      [NearbyEmptyClass(building: _b('산융', 4))],
      onTap: (n) => tapped = n,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('산융'));
    expect(tapped, '산융');
  });

  testWidgets('빈 결과 안내', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('비어 있는 강의실이 없어요'), findsOneWidget);
  });
}
