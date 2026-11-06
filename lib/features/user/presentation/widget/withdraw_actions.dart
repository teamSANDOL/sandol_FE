import 'package:flutter/material.dart';
import 'package:handori/common/component/handol_button.dart';
import 'package:handori/core/design_system/handol_tokens.dart';

/// `계속 사용하기` · 빨간 확인 버튼 한 쌍 (2196:1174 · 2196:1177).
/// 회원탈퇴 두 화면이 같이 쓴다.
class WithdrawActions extends StatelessWidget {
  const WithdrawActions({
    super.key,
    required this.confirmLabel,
    required this.onContinue,
    required this.onConfirm,
  });

  final String confirmLabel;
  final VoidCallback onContinue;

  /// null이면 비활성(회색)
  final VoidCallback? onConfirm;

  static const double height = 69;

  @override
  Widget build(BuildContext context) => Row(
    spacing: HandolSpacing.lg,
    children: [
      Expanded(
        child: HandolButton(
          label: '계속 사용하기',
          variant: HandolButtonVariant.outlined,
          height: height,
          textStyle: HandolTypography.title,
          onPressed: onContinue,
        ),
      ),
      Expanded(
        child: HandolButton(
          label: confirmLabel,
          variant: HandolButtonVariant.danger,
          height: height,
          textStyle: HandolTypography.title,
          onPressed: onConfirm,
        ),
      ),
    ],
  );
}
