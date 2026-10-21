import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/features/map/component/tuk_world_panel.dart';
import 'package:handori/features/map/data/tuk_place.dart';
import 'package:handori/features/map/presentation/provider/tuk_world_provider.dart';

Map<String, dynamic> _json(int id, String name, String? category) => {
  'id': id,
  'name': name,
  'category': category,
  'address': null,
  'naver_map_url': null,
  'kakao_map_url': null,
  'latitude': 37.34,
  'longitude': 126.73,
  'discount_info': '$name 혜택',
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-01T00:00:00Z',
  'images': <Map<String, dynamic>>[],
};

void main() {
  final places = [
    TukPlace.fromJson(_json(1, '79대포', '술집')),
    TukPlace.fromJson(_json(2, '김복남맥주', '술집')),
    TukPlace.fromJson(_json(3, '볼링장', '여가')),
  ];

  test('API 응답을 읽고 이미지 경로를 static-info 호스트 기준으로 푼다', () {
    final p = TukPlace.fromJson({
      ..._json(9, '가게', null),
      'images': [
        {'id': 1, 'url': '/static-info/tuk-world/images/1'},
        {'id': 2, 'url': 'https://cdn.example.com/a.png'},
      ],
    });
    expect(p.category, isNull);
    expect(p.imageUrls, [
      'https://sandori.kr/static-info/tuk-world/images/1',
      'https://cdn.example.com/a.png',
    ]);
  });

  Widget host(
    TukCategory? category, {
    Future<List<TukPlace>> Function()? load,
    ValueChanged<TukCategory?>? onCategory,
    ValueChanged<TukPlace>? onPlace,
  }) => ProviderScope(
    overrides: [
      tukWorldPlacesProvider.overrideWith(
        (ref) => (load ?? () async => places)(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TukWorldPanel(
          controller: ScrollController(),
          category: category,
          onCategory: onCategory ?? (_) {},
          onPlaceTap: onPlace ?? (_) {},
        ),
      ),
    ),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('분류를 고르기 전에는 분류 타일만', (tester) async {
    phone(tester);
    TukCategory? picked;
    await tester.pumpWidget(host(null, onCategory: (c) => picked = c));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('표시할 시설 선택'), findsOneWidget);
    expect(find.text('79대포'), findsNothing);
    await tester.tap(find.text('술집'));
    expect(picked, TukCategory.bar);
  });

  testWidgets('고른 분류의 업체 수와 목록', (tester) async {
    phone(tester);
    TukPlace? opened;
    await tester.pumpWidget(host(TukCategory.bar, onPlace: (p) => opened = p));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('술집  2곳', findRichText: true), findsOneWidget);
    expect(find.text('79대포'), findsOneWidget);
    expect(find.text('김복남맥주 혜택'.keepAll), findsOneWidget);
    expect(find.text('볼링장'), findsNothing);
    await tester.tap(find.text('김복남맥주'));
    expect(opened?.id, 2);
  });

  testWidgets('운영 서버에 API가 없으면 재시도 화면', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      host(null, load: () async => throw Exception('404')),
    );
    await tester.pumpAndSettle();
    expect(find.text('TUK 월드 정보를 불러오지 못했어요'.keepAll), findsOneWidget);
  });

  testWidgets('상세: 혜택 · 주소 · 지도에서 위치 보기', (tester) async {
    phone(tester);
    var shown = false;
    final p = TukPlace.fromJson({
      ..._json(1, '79대포', '술집'),
      'address': '경기 시흥시 산기대학로 237',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TukPlaceDetail(
            controller: ScrollController(),
            place: p,
            onBack: () {},
            onDirections: () {},
            onShowOnMap: () => shown = true,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('79대포 혜택'.keepAll), findsOneWidget);
    expect(find.text('경기 시흥시 산기대학로 237'.keepAll), findsOneWidget);
    await tester.tap(find.text('지도에서 위치 보기'));
    expect(shown, isTrue);
  });
}
