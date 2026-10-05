import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/domain/model/shuttle.dart';
import 'package:handori/features/notice/presentation/provider/notice_provider.dart';
import 'package:handori/features/notice/presentation/widget/notice_card.dart';
import 'package:handori/features/notice/presentation/widget/shuttle_card.dart';
import 'package:handori/shared/model/pagination_state.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 공지사항 탭 (Figma 2158:944).
///
/// 상단 바와 탭이 아래 모서리가 둥근 한 판 안에 들어가고, 목록은 primary
/// 테두리 카드 하나에 담긴다. 셔틀 탭은 시안이 아직 없어 기존 카드를 쓴다.
class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key});

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '공지사항',
        titleWidget: const Text('공지사항', style: SandolTypography.title),
        backIcon: SvgPicture.asset(SandolAssets.backArrow),
        onBack:
            () => StatefulNavigationShell.of(
              context,
            ).goBranch(RootShell.homeBranch),
        backgroundColor: SandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: SandolMetrics.pageGutter - 10,
        shape: const RoundedRectangleBorder(
          borderRadius: SandolMetrics.radiusBottom,
          side: BorderSide(color: SandolColors.border),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: SandolTypography.body,
          unselectedLabelStyle: SandolTypography.body,
          labelColor: SandolColors.text,
          unselectedLabelColor: SandolColors.text,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 4, color: SandolColors.primary),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            insets: EdgeInsets.symmetric(horizontal: SandolSpacing.sm),
          ),
          tabs: const [Tab(text: '일반 공지'), Tab(text: '기숙사'), Tab(text: '셔틀')],
        ),
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          TabBarView(
            controller: _tabController,
            children: const [
              _NoticeListTab(isDormitory: false),
              _NoticeListTab(isDormitory: true),
              _ShuttleListTab(),
            ],
          ),
        ],
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

// ── 일반 / 기숙사 공지 탭 ──────────────────────────────────────────────────────

class _NoticeListTab extends ConsumerStatefulWidget {
  const _NoticeListTab({required this.isDormitory});

  final bool isDormitory;

  @override
  ConsumerState<_NoticeListTab> createState() => _NoticeListTabState();
}

class _NoticeListTabState extends ConsumerState<_NoticeListTab> {
  late final ScrollController _scrollController = _pagingController(
    () => ref.read(_provider.notifier).loadNextPage(),
  );

  NoticeListNotifierProvider get _provider =>
      noticeListNotifierProvider(isDormitory: widget.isDormitory);

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
    return RefreshIndicator(
      color: SandolColors.primary,
      backgroundColor: SandolColors.background,
      onRefresh: () => ref.read(_provider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SandolMetrics.pageGutter,
          7,
          SandolMetrics.pageGutter,
          SandolSpacing.xl,
        ),
        children: [
          Text('총 ${data.totalCount}건', style: SandolTypography.caption),
          const SizedBox(height: SandolSpacing.xs),
          if (data.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Text(
                '공지사항이 없습니다.',
                textAlign: TextAlign.center,
                style: SandolTypography.caption.muted,
              ),
            )
          else
            SandolCard(
              borderColor: SandolColors.primary,
              padding: const EdgeInsets.fromLTRB(19, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SandolSpacing.lg,
                children: [
                  for (final notice in data.items)
                    NoticeCard(
                      notice: notice,
                      onTap:
                          () => context.push(
                            RoutePaths.noticeDetail,
                            extra: notice,
                          ),
                    ),
                  if (data.isLoadingMore) const _LoadingMore(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── 셔틀 탭 ──────────────────────────────────────────────────────────────────

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
