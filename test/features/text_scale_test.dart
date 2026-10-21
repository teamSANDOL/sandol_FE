import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_bottom_nav.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/network/fallback_interceptor.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/features/bus/component/bus_time_card.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/bus/screen/bus_time_detail_screen.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handori/features/map/presentation/provider/tuk_world_provider.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/domain/model/shuttle.dart';
import 'package:handori/features/notice/presentation/page/notice_page.dart';
import 'package:handori/features/notice/presentation/provider/notice_bookmark_provider.dart';
import 'package:handori/features/notice/presentation/provider/notice_provider.dart';
import 'package:handori/features/notice/presentation/widget/notice_card.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/page/restaurant_detail_page.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handori/shared/model/pagination_state.dart';

/// 기기 글꼴 크기(1.3 · 2.0)에서 잘림·넘침이 없는지 보는 위젯 테스트 모음.

const _scales = [1.0, 1.3, 2.0];

Widget _scaled(double scale, Widget child) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
  child: child,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 탭 화면 하나를 [RootShell] 안에 올린 라우터
GoRouter _shell(String path, Widget page) => GoRouter(
  initialLocation: path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => RootShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const Text('home'))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: path, builder: (_, _) => page)],
        ),
      ],
    ),
  ],
);

class _FixedClock extends ShuttleClock {
  _FixedClock(this.fixed);
  final DateTime fixed;
  @override
  DateTime build() => fixed;
}

class _Notices extends NoticeListNotifier {
  _Notices(this.items);
  final List<Notice> items;
  @override
  Future<PaginationState<Notice>> build({required bool isDormitory}) async =>
      PaginationState(items: items, totalCount: 2, hasMore: false);
}

class _Bookmarks extends NoticeBookmarks {
  @override
  List<Notice> build() => const [];
}

class _Shuttles extends ShuttleListNotifier {
  @override
  Future<PaginationState<Shuttle>> build() async =>
      const PaginationState(hasMore: false);
}

class _Restaurants extends RestaurantListNotifier {
  @override
  Future<List<Restaurant>> build() async => const [
    Restaurant(id: 1, name: 'TIP 가가식당', establishmentType: ''),
  ];
}

class _Meals extends MealListNotifier {
  @override
  Future<List<Meal>> build({String? date}) async => [
    Meal(
      id: 1,
      restaurantId: 1,
      mealType: MealType.dinner,
      menu: const ['김치찌개'],
      restaurantName: 'TIP 가가식당',
      registeredAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
    ),
  ];
}

Notice _notice(int id, String author) => Notice(
  id: id,
  url: 'https://example.com/$id',
  title: '공지 $id',
  author: author,
  createdAt: '2026-10-05T09:00:00',
);

void main() {
  for (final scale in _scales) {
    group('글꼴 $scale배', () {
      testWidgets('하단바: 다섯 라벨이 모두 그려진다', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          _scaled(
            scale,
            MaterialApp(
              home: Scaffold(
                bottomNavigationBar: AppBottomNav(
                  currentIndex: 0,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        for (final label in ['홈', '학식', '셔틀버스', '공지사항', '맵']) {
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('학식: 날짜 스트립 · 끼니 탭이 넘치지 않는다', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              restaurantListNotifierProvider.overrideWith(_Restaurants.new),
              mealListNotifierProvider().overrideWith(_Meals.new),
            ],
            child: _scaled(
              scale,
              MaterialApp.router(
                routerConfig: _shell('/meal', const RestaurantDetailPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('월\n'), findsOneWidget);
        expect(find.textContaining('일\n'), findsOneWidget);
        expect(find.textContaining('조식'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('공지: 저장한 공지 칩이 온전하고 북마크는 카드 오른쪽 끝에 선다', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              noticeListNotifierProvider(isDormitory: false).overrideWith(
                () => _Notices([_notice(1, '학사팀'), _notice(2, '학생지원팀 장학')]),
              ),
              noticeListNotifierProvider(
                isDormitory: true,
              ).overrideWith(() => _Notices([])),
              shuttleListNotifierProvider.overrideWith(_Shuttles.new),
              noticeBookmarksProvider.overrideWith(_Bookmarks.new),
            ],
            child: _scaled(
              scale,
              MaterialApp.router(
                routerConfig: _shell('/notice', const NoticePage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('저장한 공지'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 카드 안 북마크 버튼의 오른쪽 끝이 배지 길이와 무관하게 같다.
        final cards = find.byType(NoticeCard);
        final rights = [
          for (var i = 0; i < 2; i++)
            tester
                .getTopRight(
                  find.descendant(
                    of: cards.at(i),
                    matching: find.byType(IconButton),
                  ),
                )
                .dx,
        ];
        expect(rights[0], rights[1]);
      });

      testWidgets('셔틀 상세: 제목·경로·시각 라벨이 겹치거나 줄바꿈되지 않는다', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shuttleClockProvider.overrideWith(
                () => _FixedClock(DateTime.utc(2026, 10, 6, 10, 3)),
              ),
              userLocationProvider.overrideWith((ref) async => null),
            ],
            child: _scaled(
              scale,
              MaterialApp.router(
                routerConfig: _shell('/bus', const BusTimeDetailScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('전체 시간표'), findsOneWidget);
        expect(find.text('09시'), findsOneWidget);
        // 한 줄이면 높이가 글자 한 줄 안쪽이다(줄바꿈되면 두 배 가까이 커진다).
        expect(tester.getSize(find.text('09시')).height, lessThan(30 * scale));

        // 가운데 전환 버튼이 출발지 이름을 덮지 않는다.
        final name = tester.getRect(find.text('한국공학대 정문').first);
        final swap = tester.getRect(find.byTooltip('출발 · 도착 바꾸기'));
        expect(name.overlaps(swap), isFalse);
      });

      testWidgets('홈 셔틀 카드: 머리글과 중복된 줄 · "시" 접미사가 없다', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shuttleClockProvider.overrideWith(
                () => _FixedClock(DateTime.utc(2026, 10, 6, 10, 3)),
              ),
              userLocationProvider.overrideWith((ref) async => null),
            ],
            child: _scaled(
              scale,
              const MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(child: Bustimescreen()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('2분 뒤 출발'), findsOneWidget);
        // 10:05 편은 머리글이 이미 말하므로 목록에 다시 나오지 않는다.
        expect(find.text('10:05'), findsNothing);
        final suffixed = find.byWidgetPredicate(
          (w) =>
              w is Text && RegExp(r'^\d{1,2}:\d{2}시$').hasMatch(w.data ?? ''),
        );
        expect(suffixed, findsNothing);
      });
    });
  }

  test('TUK 월드: 운영 404 후 대체 서버가 준 목록의 이미지는 대체 서버 주소로 푼다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://prod.example.com'))
      ..httpClientAdapter = _TukAdapter();
    dio.interceptors.add(
      FallbackInterceptor(dio, fallbackBaseUrl: 'https://test.example.com'),
    );
    final container = ProviderContainer(
      overrides: [staticInfoDioProvider.overrideWith((ref) => dio)],
    );
    addTearDown(container.dispose);

    final places = await container.read(tukWorldPlacesProvider.future);
    expect(places.single.imageUrls, [
      'https://test.example.com/static-info/tuk-world/images/1',
      'https://cdn.example.com/a.png',
    ]);
  });
}

/// 운영은 404, 대체 서버는 이미지 경로가 상대 경로인 목록을 준다.
class _TukAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final prod = options.uri.host == 'prod.example.com';
    return ResponseBody.fromString(
      prod
          ? '[]'
          : jsonEncode([
            {
              'id': 1,
              'name': '가게',
              'latitude': 37.34,
              'longitude': 126.73,
              'images': [
                {'url': '/static-info/tuk-world/images/1'},
                {'url': 'https://cdn.example.com/a.png'},
              ],
            },
          ]),
      prod ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
