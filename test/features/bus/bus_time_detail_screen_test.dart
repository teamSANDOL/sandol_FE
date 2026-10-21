import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handori/features/bus/screen/bus_time_detail_screen.dart';

/// [ShuttleClock]을 고정 시각으로 바꿔 요일·시각에 따른 표시를 검사한다.
class _FixedClock extends ShuttleClock {
  _FixedClock(this.fixed);
  final DateTime fixed;
  @override
  DateTime build() => fixed;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    DateTime now, {
    Position? position,
  }) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
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
                  path: '/bus',
                  builder: (_, _) => const BusTimeDetailScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
      initialLocation: '/bus',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shuttleClockProvider.overrideWith(() => _FixedClock(now)),
          userLocationProvider.overrideWith((ref) async => position),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  // 2026-10-06(화) 10:03 — 하교 10:05 편이 2분 뒤. 10/5는 개천절 대체공휴일.
  final weekday = DateTime.utc(2026, 10, 6, 10, 3);

  testWidgets('평일: 출발·도착, 다음 버스, 시간표 강조와 수시운행 안내', (tester) async {
    await pump(tester, weekday);
    expect(find.text('한국공학대 정문'), findsOneWidget);
    expect(find.text('정왕역'), findsOneWidget);
    expect(find.text('한국공학대 정문 → 정왕역'), findsOneWidget);

    expect(find.text('2분 뒤 출발'), findsOneWidget);
    expect(find.text('10:05 출발'), findsOneWidget);

    expect(find.text('09시'), findsOneWidget);
    expect(find.text('10시'), findsOneWidget);
    expect(find.text('17:00 ~ 18:00 •수시 운행'), findsOneWidget);
    // 안내 문구는 목록 아래쪽이라 스크롤해야 그려진다.
    await tester.scrollUntilVisible(
      find.textContaining('마지막 업데이트'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('마지막 업데이트 • 오늘 10:03'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('교환 버튼을 누르면 등교 방향으로 바뀐다', (tester) async {
    await pump(tester, weekday);
    await tester.tap(find.byTooltip('출발 · 도착 바꾸기'));
    await tester.pumpAndSettle();

    expect(find.text('정왕역 → 한국공학대 정문'), findsOneWidget);
    // 등교는 10:10 편이 다음 → 7분
    expect(find.text('7분 뒤 출발'), findsOneWidget);
    expect(find.textContaining('도착버스 탑승'), findsOneWidget);
  });

  testWidgets('정류장 선택 시트에서 고른 정류장이 출발지가 된다', (tester) async {
    await pump(tester, weekday);
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    expect(find.text('출발 정류장'), findsOneWidget);

    await tester.tap(find.text('정왕역').last);
    await tester.pumpAndSettle();
    expect(find.text('정왕역 → 한국공학대 정문'), findsOneWidget);
  });

  testWidgets('제2캠퍼스를 도착으로 고르면 본교 → 제2캠퍼스(내장 시간표)', (tester) async {
    await pump(tester, weekday);
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();
    expect(find.text('한국공학대 정문 → 제2캠퍼스'), findsOneWidget);
    expect(find.text('11:00 출발'), findsOneWidget); // 10:00 편 이후

    // 출발을 정왕역으로 → 정왕역 → 본교 → 제2캠퍼스(평일 08:55·09:00 뿐).
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정왕역').last);
    await tester.pumpAndSettle();
    expect(find.text('정왕역 → 제2캠퍼스 (한국공학대 정문 경유)'), findsOneWidget);
    expect(find.text('한국공학대 정문 경유'), findsOneWidget);
    expect(find.text('직행 종료 · 환승 이용'), findsOneWidget);
  });

  testWidgets('정왕역 → 제2캠퍼스: 직행편과 본교 환승을 함께 보여 준다', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 8, 0));
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정왕역').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();

    expect(find.text('08:55 출발'), findsOneWidget); // 직행
    expect(find.text('한국공학대 정문에서 갈아타기 (예상)'.keepAll), findsOneWidget);
    expect(
      find.text('08:40 출발 (수시운행) → 본교 10:00 환승 출발'.keepAll),
      findsOneWidget,
    );
    expect(find.text('환승 시간은 교통 상황에 따라 달라질 수 있어요'.keepAll), findsOneWidget);
  });

  testWidgets('직행이 끝나도 환승이 있으면 다음 버스 카드가 환승을 안내하고, 빠듯한 편은 펼쳐 본다', (
    tester,
  ) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 10, 0));
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정왕역').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();

    expect(find.text('직행 종료 · 환승 이용'), findsOneWidget);
    expect(find.text('10:30 출발 → 본교 11:00 환승'), findsOneWidget);
    final tight = find.text('10:50 출발 (빠듯함) → 본교 11:00 환승 출발'.keepAll);
    expect(tight, findsNothing);
    await tester.tap(find.text('이전 버스도 보기'));
    await tester.pumpAndSettle();
    expect(tight, findsOneWidget);
  });

  testWidgets('평일 제2캠퍼스 → 정왕역은 직행 없음 · 환승 이용', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 9, 0));
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();
    expect(find.text('직행 없음 · 환승 이용'), findsOneWidget);
    expect(find.text('09:40 출발 → 본교 10:00 환승'), findsOneWidget);
  });

  testWidgets('직행도 환승도 없으면 운행 종료', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 20, 0));
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정왕역').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();
    expect(find.text('운행 종료'), findsOneWidget);
  });

  testWidgets('환승 연결이 없으면 안내한다', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 20, 0));
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 환승 가능한 편이 없어요'), findsOneWidget);
  });

  testWidgets('반대쪽과 같은 정류장을 고르면 출발·도착을 맞바꾼다', (tester) async {
    await pump(tester, weekday);
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국공학대 정문').last);
    await tester.pumpAndSettle();
    expect(find.text('정왕역 → 한국공학대 정문'), findsOneWidget);
  });

  testWidgets('토요일: 제2캠퍼스 → 정왕역 편만 운행', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 10, 16, 0)); // 토요일
    expect(find.text('운행 안함'), findsOneWidget); // 기본 정왕역 노선
    await tester.tap(find.byTooltip('출발 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제2캠퍼스'));
    await tester.pumpAndSettle();
    // 도착(정왕역)은 그대로 → 제2캠퍼스 → 본교 → 정왕역.
    expect(find.text('제2캠퍼스 → 정왕역 (한국공학대 정문 경유)'), findsOneWidget);
    expect(find.text('16:30 출발'), findsOneWidget);
    await tester.tap(find.byTooltip('도착 정류장 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국공학대 정문').last);
    await tester.pumpAndSettle();
    expect(find.text('제2캠퍼스 → 한국공학대 정문'), findsOneWidget);
    expect(find.text('운행 안함'), findsOneWidget);
  });

  testWidgets('주말: 미운행 안내', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 4, 10, 0)); // 일요일
    expect(find.text('운행 안함'), findsOneWidget);
    expect(find.text('오늘은 셔틀을 운행하지 않아요'), findsOneWidget);
  });

  testWidgets('20분보다 먼 출발은 출발 시각으로 보여준다', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 6, 6, 0));
    expect(find.text('09:00 출발'), findsOneWidget);
    expect(find.textContaining('분 뒤 출발'), findsNothing);
  });

  testWidgets('화면 진입 시 위치가 정왕역 근처면 정왕역 출발로 자동 선택된다', (tester) async {
    await pump(
      tester,
      weekday,
      position: Position(
        latitude: ShuttleScheduleData.stops['jeongwang']!.lat!,
        longitude: ShuttleScheduleData.stops['jeongwang']!.lng!,
        timestamp: weekday,
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    expect(find.text('정왕역 → 한국공학대 정문'), findsOneWidget);
  });
}
