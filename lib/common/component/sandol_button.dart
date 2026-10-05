import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

enum SandolButtonVariant {
  /// primary 채움 (로그인 등)
  primary,

  /// 배경색 + 36% 테두리 (계속 사용하기)
  outlined,

  /// MAIN RED 채움. 되돌릴 수 없는 동작 (회원 탈퇴하기)
  danger,
}

class SandolButton extends StatelessWidget {
  const SandolButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = SandolButtonVariant.primary,
    this.height = SandolMetrics.buttonHeight,
    this.textStyle = SandolTypography.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final SandolButtonVariant variant;
  final double height;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color foreground,
      BorderSide side,
    ) = switch (variant) {
      SandolButtonVariant.primary => (
        SandolColors.primary,
        SandolColors.background,
        BorderSide.none,
      ),
      SandolButtonVariant.outlined => (
        SandolColors.background,
        SandolColors.text,
        const BorderSide(color: SandolColors.border),
      ),
      SandolButtonVariant.danger => (
        SandolColors.red,
        SandolColors.background,
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
          disabledBackgroundColor: SandolColors.muted,
          disabledForegroundColor: SandolColors.background,
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(
            horizontal: SandolSpacing.md,
            vertical: SandolSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SandolMetrics.radius,
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
                    color: SandolColors.background,
                    semanticsLabel: label,
                  ),
                )
                : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
