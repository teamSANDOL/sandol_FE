import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/presentation/util/contact_actions.dart';

/// 조직도 노드 한 줄 (Figma 2158:891).
///
/// - 그룹: 폴더 + 이름 + 셰브런. 누르면 아래로 펼쳐진다.
/// - 부서: 진회색 원 아바타 + 이름 + 전화·링크. 최상위(depth 0)는 시안의
///   '대표연락처'처럼 이름을 강조색 20 굵게로 키운다.
/// 하위는 한 단계마다 [indent]만큼 들여쓴다.
class OrganizationNodeCard extends StatelessWidget {
  const OrganizationNodeCard({required this.node, this.depth = 0, super.key});

  static const double indent = 28;

  final OrganizationNode node;
  final int depth;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent * depth),
    child: switch (node) {
      final OrganizationGroupNode group => _GroupRow(node: group, depth: depth),
      final OrganizationUnitNode unit => _UnitRow(node: unit, depth: depth),
    },
  );
}

class _GroupRow extends StatefulWidget {
  const _GroupRow({required this.node, required this.depth});

  final OrganizationGroupNode node;
  final int depth;

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        borderRadius: SandolMetrics.radius,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SandolIconLabel(
                  icon: SvgPicture.asset(SandolAssets.orgFolder),
                  label: widget.node.name,
                  style: SandolTypography.body,
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const SandolChevron(quarterTurns: SandolChevron.down),
              ),
            ],
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child:
            _expanded
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in widget.node.children)
                      OrganizationNodeCard(node: child, depth: 1),
                  ],
                )
                : const SizedBox(width: double.infinity),
      ),
    ],
  );
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.node, required this.depth});

  final OrganizationUnitNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final phone = node.phone;
    final url = node.url;
    final top = depth == 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: top ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: top ? SandolSpacing.md : SandolSpacing.sm,
        children: [
          Text(
            node.name,
            style:
                top
                    ? SandolTypography.headline.strong.accent
                    : SandolTypography.body,
          ),
          if (phone != null || url != null)
            Row(
              spacing: SandolSpacing.lg,
              children: [
                const _Avatar(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SandolSpacing.xs,
                    children: [
                      if (phone != null)
                        _ContactLine(
                          icon: SvgPicture.asset(SandolAssets.orgPhone),
                          text: ContactActions.formatPhone(phone),
                          onTap: () => ContactActions.dial(context, phone),
                          onLongPress:
                              () => ContactActions.copy(
                                context,
                                ContactActions.formatPhone(phone),
                                label: '전화번호',
                              ),
                        ),
                      if (url != null)
                        _ContactLine(
                          icon: SvgPicture.asset(SandolAssets.orgMail),
                          text: url,
                          onTap: () => ContactActions.openUrl(context, url),
                          onLongPress:
                              () => ContactActions.copy(
                                context,
                                url,
                                label: '링크',
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 진회색 원 위의 흰 사람 아이콘 (2158:896)
class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: SandolColors.textSecondary,
      shape: BoxShape.circle,
    ),
    child: SizedBox.square(dimension: 32, child: Center(child: _AvatarIcon())),
  );
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(SandolAssets.orgAvatar);
}

/// 탭 = 네이티브 액션(전화/링크), 길게 누름 = 복사.
class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.onLongPress,
  });

  final Widget icon;
  final String text;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: SandolMetrics.radius,
    onTap: onTap,
    onLongPress: onLongPress,
    child: SandolIconLabel(
      icon: SizedBox.square(dimension: 12, child: Center(child: icon)),
      label: text,
      style: SandolTypography.body,
      gap: 14,
    ),
  );
}
