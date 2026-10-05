import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/presentation/provider/organization_provider.dart';
import 'package:handori/features/organization/presentation/util/contact_actions.dart';

/// 홈 '학과/부서 조회' 카드 (Figma 2153:352).
///
/// 자주 찾는 부서 연락처를 바로 걸 수 있게 두고, 아래 줄로 전체 조직도에
/// 들어간다. 조직도를 못 불러오면 연락처 없이 진입 줄만 남는다.
class OrganizationQuickCard extends ConsumerWidget {
  const OrganizationQuickCard({super.key, required this.onOpenAll});

  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units =
        ref.watch(pinnedOrganizationUnitsProvider).valueOrNull ?? const [];

    return SandolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (units.isNotEmpty) ...[
            // 줄마다 위아래 8씩 터치 여백이 있어 시안의 12 / 16 여백에서 뺀다.
            const SizedBox(height: SandolSpacing.xs),
            for (final unit in units) _ContactRow(unit: unit),
            const SizedBox(height: SandolSpacing.sm),
            const Divider(height: 1, thickness: 1, color: SandolColors.text),
          ],
          InkWell(
            onTap: onOpenAll,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.cardInset,
                13,
                SandolMetrics.cardInset,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '전체학과/ 부서 조회',
                          style: SandolTypography.headline,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '전체 조직도와 연락처를 확인하세요',
                          style: SandolTypography.caption.muted,
                        ),
                      ],
                    ),
                  ),
                  const SandolChevron(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 부서명 · 번호 · 전화 아이콘 한 줄. 누르면 전화, 길게 누르면 번호 복사.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.unit});

  /// 시안에서 번호 열이 시작하는 위치
  static const double _nameWidth = 138;

  final OrganizationUnitNode unit;

  @override
  Widget build(BuildContext context) {
    final phone = unit.phone!;
    return InkWell(
      onTap: () => ContactActions.dial(context, phone),
      onLongPress: () => ContactActions.copy(context, phone, label: '전화번호'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SandolMetrics.cardInset,
          vertical: SandolSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _nameWidth,
              child: Text(
                unit.name,
                style: SandolTypography.body.strong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                ContactActions.formatPhone(phone),
                style: SandolTypography.caption,
              ),
            ),
            SvgPicture.asset(SandolAssets.call, semanticsLabel: '전화 걸기'),
          ],
        ),
      ),
    );
  }
}
