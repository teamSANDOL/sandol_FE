import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handol/core/utils/korea_time.dart';
import 'package:handol/features/bus/component/bus_time_card.dart';
import 'package:handol/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handol/features/empty_class/presentation/provider/user_location_provider.dart';

class _FixedClock extends ShuttleClock {
  _FixedClock(this.fixed);
  final DateTime fixed;
  @override
  DateTime build() => fixed;
}

void main() {
  testWidgets('홈 카드의 방향 전환 · 새로고침은 카드 이동 대신 제 동작을 한다', (tester) async {
    var opened = 0;
    // 공유 시계는 10:03(UTC 입력), 초는 실제 시계에서 읽으므로 48초로 고정.
    KoreaTime.clock = () => DateTime.utc(2026, 10, 6, 1, 3, 48);
    addTearDown(() => KoreaTime.clock = DateTime.now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shuttleClockProvider.overrideWith(
            () => _FixedClock(DateTime.utc(2026, 10, 6, 10, 3)),
          ),
          userLocationProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Bustimescreen(onTap: () => opened++),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('학교'), findsOneWidget);
    // 10:03:48 → 10:05 편까지 72초.
    expect(find.text('1분 12초 뒤 출발'), findsOneWidget);

    // 버튼 옆 띠를 눌러도 셔틀 화면으로 넘어가지 않는다.
    await tester.tap(find.text('학교'));
    expect(opened, 0);

    await tester.tap(find.byTooltip('반대 방향'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(find.text('정왕역').first).dx,
      lessThan(tester.getTopLeft(find.text('학교')).dx),
    );

    await tester.tap(find.byTooltip('새로고침'));
    await tester.pump();
    expect(opened, 0);

    // 띠 아래 본문은 그대로 카드 탭.
    // 띠 아래 정류장 이름(띠의 '정왕역'이 먼저 나온다).
    await tester.tap(find.text('정왕역').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opened, 1);
  });
}
