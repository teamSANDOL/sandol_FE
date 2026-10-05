import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_radius.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 진행 중 다이얼로그를 띄운 채 [task] 를 수행한다. 예외는 그대로 올린다.
/// 로그아웃·회원탈퇴처럼 서버를 기다리는 동안 화면을 잠근다.
Future<void> runBlocking(
  BuildContext context,
  Future<void> Function() task,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .5),
    builder: (_) => const Center(child: SandolLoadingIndicator()),
  );
  try {
    await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

// ── 확인 다이얼로그 ──────────────────────────────────────────────
//
// 기본 AlertDialog(밋밋한 흰 배경 + 텍스트 버튼) 대신 앱 톤에 맞춘
// 커스텀 다이얼로그. 상단에 옅은 붉은 원 안의 아이콘, 가운데 정렬 제목·설명,
// 하단에 [취소 · 확인] 버튼 쌍(파괴적 동작은 붉은 채움 버튼)을 둔다.

class ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final bool showCancel;

  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.value),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: .08),
              ),
              child: Icon(icon, size: 28, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (showCancel) ...[
                  Expanded(
                    child: _DialogButton(
                      label: '취소',
                      background: const Color(0xFFF2F3F5),
                      foreground: AppColors.textSecondary,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    background: AppColors.danger,
                    foreground: Colors.white,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.value),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.value),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
