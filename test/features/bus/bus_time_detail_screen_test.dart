import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/bus/screen/bus_time_detail_screen.dart';

/// [ShuttleClock]을 고정 시각으로 바꿔 요일·시각에 따른 표시를 검사한다.
class _FixedClock extends ShuttleClock {
  _FixedClock(this.fixed);
  final DateTime fixed;
  @override
  DateTime build() => fixed;
}

void main() {
  Future<void> pump(WidgetTester tester, DateTime now) async {
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
        overrides: [shuttleClockProvider.overrideWith(() => _FixedClock(now))],
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

    expect(find.text('2분 후 출발'), findsOneWidget);
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
    expect(find.text('7분 후 출발'), findsOneWidget);
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

  testWidgets('주말: 미운행 안내', (tester) async {
    await pump(tester, DateTime.utc(2026, 10, 4, 10, 0)); // 일요일
    expect(find.text('운행 안함'), findsOneWidget);
    expect(find.text('오늘은 셔틀을 운행하지 않아요'), findsOneWidget);
  });
}
