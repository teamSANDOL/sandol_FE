import 'package:flutter/material.dart';
import 'package:handori/core/design_system/handol_tokens.dart';

/// 선택되지 않은 칩의 모양.
enum HandolChipStyle {
  /// main40 바탕에 검은 글씨 (홈 2153:231)
  tint,

  /// 회색 바탕에 흰 글씨 (학식 2158:731)
  solid,
}

/// 선택 칩. 선택되면 primary 바탕에 굵은 흰 글씨.
class HandolChip extends StatelessWidget {
  const HandolChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.style = HandolChipStyle.tint,
  });

  static const double height = 39;
  static const double minWidth = 98;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final HandolChipStyle style;

  @override
  Widget build(BuildContext context) => Material(
    color:
        selected
            ? HandolColors.primary
            : switch (style) {
              HandolChipStyle.tint => HandolColors.primary40,
              HandolChipStyle.solid => HandolColors.inactive,
            },
    borderRadius: HandolMetrics.radius,
    child: InkWell(
      borderRadius: HandolMetrics.radius,
      onTap: onTap,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: HandolSpacing.md),
        alignment: Alignment.center,
        child: Text(
          label,
          style:
              selected
                  ? HandolTypography.caption.strong.onPrimary
                  : switch (style) {
                    HandolChipStyle.tint => HandolTypography.caption,
                    HandolChipStyle.solid => HandolTypography.caption.onPrimary,
                  },
        ),
      ),
    ),
  );
}
