import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/features/home/component/schedule_section.dart';
import 'package:handori/features/home/model/schedule_event.dart';
import 'package:handori/features/home/presentation/provider/home_static_provider.dart';

void main() {
  final event = ScheduleEvent(
    title: 'Techno Festival',
    start: DateTime(2099, 9, 29),
    end: DateTime(2099, 10, 1),
  );

  Future<void> pumpSection(
    WidgetTester tester, {
    required ScheduleEvent? event,
    VoidCallback? onClose,
    VoidCallback? onDetail,
  }) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(33),
            child: ScheduleSection(
              event: event,
              today: DateTime(2099, 9, 19),
              onClose: onClose ?? () {},
              onDetail: onDetail ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('고정한 일정: X는 고정 해제, 자세히보기', (tester) async {
    var closed = 0, detail = 0;
    await pumpSection(
      tester,
      event: event,
      onClose: () => closed++,
      onDetail: () => detail++,
    );
    expect(find.text('Techno Festival'), findsOneWidget);
    expect(find.text('D-10'), findsOneWidget);

    await tester.tap(find.byTooltip('고정 해제'));
    await tester.tap(find.text('자세히보기'));
    expect((closed, detail), (1, 1));
  });

  testWidgets('빈 카드(2270:498): 문구 · 잠자는 산돌이 · X 닫기 · 자세히보기', (tester) async {
    var closed = 0, detail = 0;
    await pumpSection(
      tester,
      event: null,
      onClose: () => closed++,
      onDetail: () => detail++,
    );
    expect(find.text('주요일정'), findsOneWidget);
    expect(find.text('아직 고정한 스케줄이 없어요'), findsOneWidget);
    // 별 1 + 산돌이 레이어 5 + X 1 + 셰브런 1
    expect(find.byType(SvgPicture), findsNWidgets(8));
    // 시안 frame: 홈 카드 폭(412 - 33×2) × 142
    expect(tester.getSize(find.byType(SandolCard)), const Size(346, 142));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('닫기'));
    await tester.tap(find.text('자세히보기'));
    expect((closed, detail), (1, 1));
  });

  testWidgets('홈 흐름: 처음엔 일정 카드, X를 누르면 같은 자리에 빈 카드', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleEventsProvider.overrideWithValue([event]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final async = ref.watch(homeScheduleProvider);
                if (!async.hasValue) return const SizedBox.shrink();
                final schedule = async.value;
                return ScheduleSection(
                  event: schedule,
                  today: DateTime(2099, 9, 19),
                  onClose:
                      () => ref
                          .read(dismissedSchedulesProvider.notifier)
                          .dismiss(schedule!.id),
                  onDetail: () {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Techno Festival'), findsOneWidget);
    expect(find.text('아직 고정한 스케줄이 없어요'), findsNothing);

    await tester.tap(find.byTooltip('고정 해제'));
    await tester.pumpAndSettle();
    expect(find.text('Techno Festival'), findsNothing);
    expect(find.text('주요일정'), findsOneWidget);
    expect(find.text('아직 고정한 스케줄이 없어요'), findsOneWidget);
  });

  test('고정 해제는 저장돼 다시 열어도 빈 카드', () async {
    FlutterSecureStorage.setMockInitialValues({});
    ProviderContainer open() => ProviderContainer(
      overrides: [
        scheduleEventsProvider.overrideWithValue([event]),
      ],
    );

    final first = open();
    expect(await first.read(homeScheduleProvider.future), event);
    await first.read(dismissedSchedulesProvider.notifier).dismiss(event.id);
    expect(await first.read(homeScheduleProvider.future), isNull);
    first.dispose();

    // 앱을 새로 켠 것처럼 새 컨테이너
    final second = open();
    addTearDown(second.dispose);
    expect(await second.read(homeScheduleProvider.future), isNull);
  });
}
