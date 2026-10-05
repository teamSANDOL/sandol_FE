import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/domain/model/shuttle.dart';
import 'package:handori/features/notice/presentation/page/notice_page.dart';
import 'package:handori/features/notice/presentation/provider/notice_provider.dart';
import 'package:handori/shared/model/pagination_state.dart';

class _Notices extends NoticeListNotifier {
  _Notices(this.items);
  final List<Notice> items;
  @override
  Future<PaginationState<Notice>> build({required bool isDormitory}) async =>
      PaginationState(items: items, totalCount: 123, hasMore: false);
}

class _Shuttles extends ShuttleListNotifier {
  @override
  Future<PaginationState<Shuttle>> build() async =>
      const PaginationState(hasMore: false);
}

void main() {
  test('날짜 표기 "yyyy. MM. dd."', () {
    expect(DateFormatter.dotted('2026-10-05T09:00:00'), '2026. 10. 05.');
    expect(DateFormatter.dotted('잘못된 값'), '잘못된 값');
  });

  testWidgets('탭 · 총 건수 · 공지 목록(부서 · 제목 · 날짜)', (tester) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const notice = Notice(
      id: 1,
      url: 'https://example.com/1',
      title: '2026학년도 2학기 수강신청 안내',
      author: '학사팀',
      createdAt: '2026-10-05T09:00:00',
    );
    final router = GoRouter(
      initialLocation: '/notice',
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
                GoRoute(path: '/notice', builder: (_, _) => const NoticePage()),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticeListNotifierProvider(
            isDormitory: false,
          ).overrideWith(() => _Notices([notice])),
          noticeListNotifierProvider(
            isDormitory: true,
          ).overrideWith(() => _Notices([])),
          shuttleListNotifierProvider.overrideWith(_Shuttles.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('일반 공지'), findsOneWidget);
    expect(find.text('총 123건'), findsOneWidget);
    expect(find.text('학사팀'), findsOneWidget);
    expect(find.text('2026학년도 2학기 수강신청 안내'), findsOneWidget);
    expect(find.text('2026. 10. 05.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('기숙사'));
    await tester.pumpAndSettle();
    expect(find.text('공지사항이 없습니다.'), findsOneWidget);
  });
}
