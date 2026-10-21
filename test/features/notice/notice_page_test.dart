import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/domain/model/shuttle.dart';
import 'package:handori/features/notice/presentation/page/notice_page.dart';
import 'package:handori/features/notice/presentation/provider/notice_bookmark_provider.dart';
import 'package:handori/features/notice/presentation/provider/notice_filter.dart';
import 'package:handori/features/notice/presentation/provider/notice_provider.dart';
import 'package:handori/shared/model/pagination_state.dart';

class _Notices extends NoticeListNotifier {
  _Notices(this.items);
  final List<Notice> items;
  @override
  Future<PaginationState<Notice>> build({required bool isDormitory}) async =>
      PaginationState(items: items, totalCount: 123, hasMore: false);
}

/// 보안 저장소 없이 메모리에서만 도는 저장 공지
class _Bookmarks extends NoticeBookmarks {
  @override
  List<Notice> build() => const [];

  @override
  Future<void> toggle(Notice notice) async {
    state =
        isSaved(notice.id)
            ? state.where((n) => n.id != notice.id).toList()
            : [notice, ...state];
  }
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

  Notice notice(int id, String author, String title) => Notice(
    id: id,
    url: 'https://example.com/$id',
    title: title,
    author: author,
    createdAt: '2026-10-05T09:00:00',
  );

  test('분류·검색은 부서와 제목에서 키워드를 찾는다', () {
    final items = [
      notice(1, '학사팀', '수강신청 안내'),
      notice(2, '장학팀', '국가장학금 신청'),
      notice(3, '총무팀', '주차장 공사 안내'),
    ];
    List<int> ids(NoticeFilter f, [String q = '']) =>
        filterNotices(items, filter: f, query: q).map((n) => n.id).toList();

    expect(ids(NoticeFilter.all), [1, 2, 3]);
    expect(ids(NoticeFilter.academic), [1]);
    expect(ids(NoticeFilter.scholarship), [2]);
    expect(ids(NoticeFilter.general), [3]);
    expect(ids(NoticeFilter.all, ' 주차 '), [3]);
  });

  testWidgets('검색창 · 분류 칩 · 총 건수 · 카드(부서 · 제목 · 날짜) · 저장', (tester) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final items = [
      notice(1, '학사팀', '2026학년도 2학기 수강신청 안내'),
      notice(2, '총무팀', '주차장 공사 안내'),
    ];
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
          ).overrideWith(() => _Notices(items)),
          noticeListNotifierProvider(
            isDormitory: true,
          ).overrideWith(() => _Notices([])),
          shuttleListNotifierProvider.overrideWith(_Shuttles.new),
          noticeBookmarksProvider.overrideWith(_Bookmarks.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('어떤 공지를 찾고 있나요?'), findsOneWidget);
    for (final f in NoticeFilter.values) {
      expect(find.text(f.label), findsOneWidget);
    }
    expect(find.text('총 123건'), findsOneWidget);
    expect(find.text('학사팀'), findsOneWidget);
    expect(find.text('2026학년도 2학기 수강신청 안내'), findsOneWidget);
    expect(find.text('2026.10.05.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // 분류 칩: 학사만 남고 건수는 거른 개수
    await tester.tap(find.text('학사'));
    await tester.pumpAndSettle();
    expect(find.text('총 1건'), findsOneWidget);
    expect(find.text('주차장 공사 안내'), findsNothing);

    // 검색: 일치하는 게 없으면 빈 안내
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '없는검색어');
    await tester.pumpAndSettle();
    expect(find.text('공지사항이 없습니다.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '주차');
    await tester.pumpAndSettle();
    expect(find.text('주차장 공사 안내'), findsOneWidget);

    // 저장 후 '저장한 공지' 칩에 나타난다
    await tester.tap(find.byTooltip('저장'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('저장한 공지'));
    await tester.pumpAndSettle();
    expect(find.text('총 1건'), findsOneWidget);
    expect(find.text('주차장 공사 안내'), findsOneWidget);

    await tester.tap(find.text('생활관'));
    await tester.pumpAndSettle();
    expect(find.text('공지사항이 없습니다.'), findsOneWidget);
  });
}
