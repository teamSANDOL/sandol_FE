import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/handol_card.dart';
import 'package:handori/core/design_system/handol_assets.dart';
import 'package:handori/core/design_system/handol_tokens.dart';
import 'package:handori/core/utils/external_link.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/features/user/data/policy_document.dart';
import 'package:handori/shared/widget/handol_loading_indicator.dart';

/// 서비스 이용약관 · 개인정보처리방침을 앱 안에서 보여 준다.
class PolicyPage extends ConsumerWidget {
  const PolicyPage({super.key, required this.doc});

  final PolicyDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(policyProvider(doc));
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: HandolColors.background,
      appBar: AppTopBar(
        title: doc.label,
        titleWidget: Text(doc.label, style: HandolTypography.title),
        backIcon: SvgPicture.asset(HandolAssets.backArrow),
        onBack: () => context.pop(),
        showUser: false,
        backgroundColor: HandolColors.background,
        horizontalPadding: HandolMetrics.pageGutter - 10,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: HandolGradients.screen),
        child: content.when(
          loading: () => const Center(child: HandolLoadingIndicator()),
          error:
              (_, _) => _ErrorView(
                onRetry: () => ref.invalidate(policyProvider(doc)),
                onOpenWeb: () => openExternalLink(context, doc.url),
              ),
          data:
              (policy) => ListView(
                padding: EdgeInsets.fromLTRB(
                  HandolMetrics.pageGutter,
                  HandolSpacing.md,
                  HandolMetrics.pageGutter,
                  HandolSpacing.xl + bottom,
                ),
                children: [
                  if (policy.intro case final String intro)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HandolSpacing.md),
                      child: Text(
                        intro.keepAll,
                        style: HandolTypography.body.muted,
                      ),
                    ),
                  HandolCard(
                    padding: const EdgeInsets.fromLTRB(
                      HandolMetrics.cardInset,
                      HandolSpacing.sm,
                      HandolMetrics.cardInset,
                      HandolSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final b in policy.blocks) _Block(b)],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block);

  final PolicyBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.isHeading) {
      return Padding(
        padding: const EdgeInsets.only(top: HandolSpacing.lg, bottom: 6),
        child: Text(block.text.keepAll, style: HandolTypography.headline),
      );
    }
    final text = Text(
      block.text.keepAll,
      style: HandolTypography.body.copyWith(height: 1.6),
    );
    return Padding(
      // 항목 안의 항목은 머리표 칸(24)만큼 더 들어간다.
      padding: EdgeInsets.only(
        top: 6,
        left: 24.0 * (block.depth - (block.marker == null ? 0 : 1)),
      ),
      child: switch (block.marker) {
        final String marker => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                marker,
                style: HandolTypography.body.copyWith(height: 1.6).muted,
              ),
            ),
            Expanded(child: text),
          ],
        ),
        null => text,
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.onOpenWeb});

  final VoidCallback onRetry;
  final VoidCallback onOpenWeb;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(HandolMetrics.pageGutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: HandolSpacing.sm,
        children: [
          Text('문서를 불러오지 못했어요.'.keepAll, style: HandolTypography.body.muted),
          TextButton(
            onPressed: onRetry,
            child: Text('다시 시도', style: HandolTypography.caption.accent),
          ),
          TextButton(
            onPressed: onOpenWeb,
            child: Text('웹에서 보기', style: HandolTypography.caption.muted),
          ),
        ],
      ),
    ),
  );
}
