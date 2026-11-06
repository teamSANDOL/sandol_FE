import 'package:flutter/material.dart';
import 'package:handori/core/design_system/handol_tokens.dart';

enum HandolButtonVariant {
  /// primary 채움 (로그인 등)
  primary,

  /// 배경색 + 36% 테두리 (계속 사용하기)
  outlined,

  /// MAIN RED 채움. 되돌릴 수 없는 동작 (회원 탈퇴하기)
  danger,
}

class HandolButton extends StatelessWidget {
  const HandolButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = HandolButtonVariant.primary,
    this.height = HandolMetrics.buttonHeight,
    this.textStyle = HandolTypography.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final HandolButtonVariant variant;
  final double height;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color foreground,
      BorderSide side,
    ) = switch (variant) {
      HandolButtonVariant.primary => (
        HandolColors.primary,
        HandolColors.background,
        BorderSide.none,
      ),
      HandolButtonVariant.outlined => (
        HandolColors.background,
        HandolColors.text,
        const BorderSide(color: HandolColors.border),
      ),
      HandolButtonVariant.danger => (
        HandolColors.red,
        HandolColors.background,
        BorderSide.none,
      ),
    };
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: HandolColors.muted,
          disabledForegroundColor: HandolColors.background,
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(
            horizontal: HandolSpacing.md,
            vertical: HandolSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: HandolMetrics.radius,
            side: side,
          ),
          textStyle: textStyle,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child:
            loading
                ? SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HandolColors.background,
                    semanticsLabel: label,
                  ),
                )
                : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
