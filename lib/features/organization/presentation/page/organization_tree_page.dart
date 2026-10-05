import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/domain/model/organization_search_result.dart';
import 'package:handori/features/organization/presentation/provider/organization_provider.dart';
import 'package:handori/features/organization/presentation/widget/organization_node_card.dart';
import 'package:handori/features/organization/presentation/widget/organization_search_result_card.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 학과/부서 조직도 (Figma 2158:882).
///
/// 검색창 아래 카드 하나에 트리를 담는다. 검색어가 있으면 트리 대신
/// 앱 안에서 부분일치로 거른 결과를 같은 카드에 보여준다.
class OrganizationTreePage extends ConsumerStatefulWidget {
  const OrganizationTreePage({super.key});

  @override
  ConsumerState<OrganizationTreePage> createState() =>
      _OrganizationTreePageState();
}

class _OrganizationTreePageState extends ConsumerState<OrganizationTreePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(organizationTreeNotifierProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(organizationTreeNotifierProvider);

    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '학과/부서 조직도',
        titleWidget: const Text('학과/부서 조직도', style: SandolTypography.title),
        backIcon: SvgPicture.asset(SandolAssets.backArrow),
        onBack: () => context.pop(),
        backgroundColor: SandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: SandolMetrics.pageGutter - 10,
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          RefreshIndicator(
            color: SandolColors.primary,
            backgroundColor: SandolColors.background,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.pageGutter,
                SandolSpacing.sm,
                SandolMetrics.pageGutter,
                SandolSpacing.xl,
              ),
              children: [
                _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 21),
                treeAsync.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: SandolLoadingIndicator()),
                      ),
                  error:
                      (_, _) => ErrorRetryView(
                        title: '조직도를 불러오지 못했어요',
                        onRetry: _refresh,
                      ),
                  data:
                      (root) =>
                          _query.isEmpty
                              ? _TreeCard(root: root)
                              : _SearchResultCard(
                                results: searchOrganizationTree(root, _query),
                              ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 돋보기 + 입력칸 (2158:884)
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SandolCard(
    padding: const EdgeInsets.fromLTRB(10, 12, SandolMetrics.cardInset, 12),
    child: Row(
      spacing: 11,
      children: [
        SvgPicture.asset(SandolAssets.orgSearch),
        Expanded(
          child: TextField(
            controller: controller,
            style: SandolTypography.caption,
            decoration: InputDecoration.collapsed(
              hintText: '학과 또는 부서 이름 검색',
              hintStyle: SandolTypography.caption.muted,
            ),
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ),
      ],
    ),
  );
}

/// 트리 카드 (2158:891): 최상위 부서(대표연락처)와 그룹 목록
class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.root});

  final OrganizationGroupNode root;

  static const _padding = EdgeInsets.symmetric(
    horizontal: SandolMetrics.cardInset,
    vertical: 32,
  );

  @override
  Widget build(BuildContext context) {
    final units = root.children.whereType<OrganizationUnitNode>();
    final groups = root.children.whereType<OrganizationGroupNode>();
    return SandolCard(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: [
          for (final unit in units) OrganizationNodeCard(node: unit),
          if (groups.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in groups) OrganizationNodeCard(node: group),
              ],
            ),
        ],
      ),
    );
  }
}

/// 검색어 입력 중 트리 대신 같은 카드 틀에 보여주는 부분일치 결과
class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.results});

  final List<OrganizationSearchResult> results;

  @override
  Widget build(BuildContext context) => SandolCard(
    padding: _TreeCard._padding,
    child:
        results.isEmpty
            ? Text(
              '검색 결과가 없습니다.',
              textAlign: TextAlign.center,
              style: SandolTypography.caption.muted,
            )
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SandolSpacing.md,
              children: [
                for (final r in results)
                  OrganizationSearchResultCard(result: r),
              ],
            ),
  );
}
