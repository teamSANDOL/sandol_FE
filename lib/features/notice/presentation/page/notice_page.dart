import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/domain/model/shuttle.dart';
import 'package:handori/features/notice/presentation/provider/notice_bookmark_provider.dart';
import 'package:handori/features/notice/presentation/provider/notice_filter.dart';
import 'package:handori/features/notice/presentation/provider/notice_provider.dart';
import 'package:handori/features/notice/presentation/widget/notice_card.dart';
import 'package:handori/features/notice/presentation/widget/notice_style.dart';
import 'package:handori/features/notice/presentation/widget/shuttle_card.dart';
import 'package:handori/shared/model/pagination_state.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 공지사항 탭 (Figma 공지사항2).
///
/// 그라데이션 배경 위에 검색창 · 분류 칩 · 공지별 카드가 쌓인다.
/// 공지 API 는 페이지 번호·크기만 받으므로 검색과 분류(생활관 제외)는 지금까지
/// 불러온 목록 안에서 거른다. 셔틀 사진 공지는 시안에 자리가 없어 칩 하나로 둔다.
class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key});

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage> {
  final _searchController = TextEditingController();
  NoticeFilter _filter = NoticeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: NoticeColors.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppTopBar(
          title: '공지사항',
          titleWidget: const Text('공지사항', style: SandolTypography.title),
          backIcon: SvgPicture.asset(SandolAssets.backArrow),
          onBack:
              () => StatefulNavigationShell.of(
                context,
              ).goBranch(RootShell.homeBranch),
          backgroundColor: Colors.transparent,
          // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
          horizontalPadding: SandolMetrics.pageGutter - 10,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.pageGutter,
                SandolSpacing.sm,
                SandolMetrics.pageGutter,
                0,
              ),
              child: _SearchBox(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.pageGutter,
                SandolSpacing.md,
                SandolMetrics.pageGutter,
                0,
              ),
              child: _FilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final query = _searchController.text;
    return switch (_filter) {
      NoticeFilter.shuttle => const _ShuttleListTab(),
      NoticeFilter.saved => _SavedList(query: query),
      _ => _NoticeListTab(
        // 분류를 바꾸면 스크롤 위치도 새로 시작한다.
        key: ValueKey(_filter),
        filter: _filter,
        query: query,
      ),
    };
  }
}

/// 검색창 (Figma Frame 2147234866): 돋보기 · 힌트 · 오른쪽 필터 아이콘.
/// 입력이 있으면 필터 아이콘 자리가 지우기 버튼이 된다.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: SandolColors.background,
      borderRadius: SandolMetrics.radius,
      border: Border.all(color: NoticeColors.border),
    ),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11),
          child: Icon(
            Icons.search_rounded,
            size: SandolMetrics.iconSize,
            color: SandolColors.primary,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: SandolTypography.caption,
            decoration: InputDecoration(
              hintText: '어떤 공지를 찾고 있나요?',
              hintStyle: SandolTypography.caption.muted,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child:
              controller.text.isEmpty
                  ? const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: SandolColors.muted,
                  )
                  : IconButton(
                    tooltip: '검색어 지우기',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: SandolColors.muted,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
        ),
      ],
    ),
  );
}

/// 분류 칩 줄 (Figma Frame 2147235232): 한 줄 4개, 칸 사이 7 · 줄 사이 8.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final NoticeFilter selected;
  final ValueChanged<NoticeFilter> onSelected;

  static const _gap = 7.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - _gap * 3) / 4;
      return Wrap(
        spacing: _gap,
        runSpacing: SandolSpacing.sm,
        children: [
          for (final f in NoticeFilter.values)
            SizedBox(
              width: width,
              child: _FilterChip(
                filter: f,
                selected: f == selected,
                onTap: () => onSelected(f),
              ),
            ),
        ],
      );
    },
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final NoticeFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style =
        selected
            ? SandolTypography.caption.onPrimary
            : SandolTypography.caption;
    return Material(
      color: selected ? SandolColors.primary : SandolColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: SandolMetrics.radius,
        side: BorderSide(
          color: selected ? SandolColors.primary : NoticeColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: SandolMetrics.radius,
        ),
        onTap: onTap,
        // 아이콘과 글자를 한 덩어리로 묶어, 큰 글꼴(1.3배 상한)에서 칸보다 크면
        // 단어 중간에서 끊지 않고 통째로 줄여 맞춘다. 높이는 최소값만 둔다.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: SandolSpacing.xs,
                  children: [
                    if (filter == NoticeFilter.saved)
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 14,
                        color: style.color,
                      ),
                    Text(
                      filter.label,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 끝 300px 안에 들어오면 다음 페이지를 요청하는 스크롤 컨트롤러.
ScrollController _pagingController(VoidCallback loadNextPage) {
  late final ScrollController controller;
  controller =
      ScrollController()..addListener(() {
        if (controller.position.maxScrollExtent - controller.offset <= 300) {
          loadNextPage();
        }
      });
  return controller;
}

/// 목록 맨 아래의 '더 불러오는 중' 표시
class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(SandolSpacing.md),
    child: Center(child: SandolLoadingIndicator()),
  );
}

// ── 공지 목록 (전체 · 분류 · 생활관) ─────────────────────────────────────────

class _NoticeListTab extends ConsumerStatefulWidget {
  const _NoticeListTab({required this.filter, required this.query, super.key});

  final NoticeFilter filter;
  final String query;

  @override
  ConsumerState<_NoticeListTab> createState() => _NoticeListTabState();
}

class _NoticeListTabState extends ConsumerState<_NoticeListTab> {
  late final ScrollController _scrollController = _pagingController(
    () => ref.read(_provider.notifier).loadNextPage(),
  );

  NoticeListNotifierProvider get _provider => noticeListNotifierProvider(
    isDormitory: widget.filter == NoticeFilter.dormitory,
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(_provider)
        .when(
          data: _buildList,
          loading: () => const Center(child: SandolLoadingIndicator()),
          error:
              (e, _) => ErrorRetryView(
                title: '공지사항을 불러올 수 없습니다.',
                onRetry: () => ref.invalidate(_provider),
              ),
        );
  }

  Widget _buildList(PaginationState<Notice> data) {
    final items = filterNotices(
      data.items,
      filter: widget.filter,
      query: widget.query,
    );
    // 거르지 않았을 때만 서버가 센 전체 건수를 그대로 보여 준다.
    final narrowed = widget.filter.isKeyword || widget.query.trim().isNotEmpty;
    return _NoticeListView(
      items: items,
      total: narrowed ? items.length : data.totalCount,
      controller: _scrollController,
      isLoadingMore: data.isLoadingMore,
      onRefresh: () => ref.read(_provider.notifier).refresh(),
    );
  }
}

// ── 저장한 공지 ──────────────────────────────────────────────────────────────

class _SavedList extends ConsumerWidget {
  const _SavedList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = filterNotices(
      ref.watch(noticeBookmarksProvider),
      filter: NoticeFilter.saved,
      query: query,
    );
    return _NoticeListView(
      items: items,
      total: items.length,
      emptyText: '저장한 공지가 없습니다.',
    );
  }
}

/// 요약 줄('최신 공지 · 총 N건 · 최신순') 아래에 공지 카드를 늘어놓는다.
class _NoticeListView extends ConsumerWidget {
  const _NoticeListView({
    required this.items,
    required this.total,
    this.controller,
    this.isLoadingMore = false,
    this.onRefresh,
    this.emptyText = '공지사항이 없습니다.',
  });

  final List<Notice> items;
  final int total;
  final ScrollController? controller;
  final bool isLoadingMore;
  final Future<void> Function()? onRefresh;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(noticeBookmarksProvider);
    final list = ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        0,
        SandolMetrics.pageGutter,
        SandolSpacing.xl,
      ),
      children: [
        _SummaryRow(total: total),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: SandolTypography.caption.muted,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SandolSpacing.sm,
            children: [
              for (final notice in items)
                NoticeCard(
                  notice: notice,
                  saved: bookmarks.any((b) => b.id == notice.id),
                  onToggleSaved:
                      () => ref
                          .read(noticeBookmarksProvider.notifier)
                          .toggle(notice),
                  onTap:
                      () =>
                          context.push(RoutePaths.noticeDetail, extra: notice),
                ),
              if (isLoadingMore) const _LoadingMore(),
            ],
          ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(
      color: SandolColors.primary,
      backgroundColor: SandolColors.background,
      onRefresh: onRefresh!,
      child: list,
    );
  }
}

/// '최신 공지  총 N건' 과 오른쪽 '최신순' 표시 (Figma Frame 2147235230).
/// API 가 최신순만 주므로 정렬 표시는 누를 수 없다.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SandolSpacing.sm),
    child: Row(
      children: [
        // 큰 글꼴에서는 '총 N건'이 아래 줄로 내려가게 Wrap 으로 둔다.
        Expanded(
          child: Wrap(
            spacing: SandolSpacing.sm,
            children: [
              Text('최신 공지', style: SandolTypography.caption),
              Text('총 $total건', style: SandolTypography.caption),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: SandolColors.background,
            borderRadius: SandolMetrics.radius,
            border: Border.all(color: NoticeColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('최신순', style: SandolTypography.caption),
                const Icon(Icons.arrow_drop_down_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ── 셔틀 사진 공지 ───────────────────────────────────────────────────────────

class _ShuttleListTab extends ConsumerStatefulWidget {
  const _ShuttleListTab();

  @override
  ConsumerState<_ShuttleListTab> createState() => _ShuttleListTabState();
}

class _ShuttleListTabState extends ConsumerState<_ShuttleListTab> {
  late final ScrollController _scrollController = _pagingController(
    () => ref.read(shuttleListNotifierProvider.notifier).loadNextPage(),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(shuttleListNotifierProvider)
        .when(
          data: _buildList,
          loading: () => const Center(child: SandolLoadingIndicator()),
          error:
              (e, _) => ErrorRetryView(
                title: '셔틀 정보를 불러올 수 없습니다.',
                onRetry: () => ref.invalidate(shuttleListNotifierProvider),
              ),
        );
  }

  Widget _buildList(PaginationState<Shuttle> data) {
    return RefreshIndicator(
      color: SandolColors.primary,
      backgroundColor: SandolColors.background,
      onRefresh: () => ref.read(shuttleListNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: SandolSpacing.sm),
        itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
        itemBuilder:
            (context, index) =>
                index == data.items.length
                    ? const _LoadingMore()
                    : ShuttleCard(shuttle: data.items[index]),
      ),
    );
  }
}
