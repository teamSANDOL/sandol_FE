import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 선택되지 않은 칩의 모양.
enum SandolChipStyle {
  /// main40 바탕에 검은 글씨 (홈 2153:231)
  tint,

  /// 회색 바탕에 흰 글씨 (학식 2158:731)
  solid,
}

/// 선택 칩. 선택되면 primary 바탕에 굵은 흰 글씨.
class SandolChip extends StatelessWidget {
  const SandolChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.style = SandolChipStyle.tint,
  });

  static const double height = 39;
  static const double minWidth = 98;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final SandolChipStyle style;

  @override
  Widget build(BuildContext context) => Material(
    color:
        selected
            ? SandolColors.primary
            : switch (style) {
              SandolChipStyle.tint => SandolColors.primary40,
              SandolChipStyle.solid => SandolColors.inactive,
            },
    borderRadius: SandolMetrics.radius,
    child: InkWell(
      borderRadius: SandolMetrics.radius,
      onTap: onTap,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: SandolSpacing.md),
        alignment: Alignment.center,
        child: Text(
          label,
          style:
              selected
                  ? SandolTypography.caption.strong.onPrimary
                  : switch (style) {
                    SandolChipStyle.tint => SandolTypography.caption,
                    SandolChipStyle.solid => SandolTypography.caption.onPrimary,
                  },
        ),
      ),
    ),
  );
}
