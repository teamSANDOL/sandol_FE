import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';

/// 목록·트리를 못 불러왔을 때 공통으로 쓰는 오류 화면.
///
/// 예외 원문 대신 사용자 문구를 보여주고 재시도 버튼을 준다. 화면마다
/// 아이콘·문구·버튼이 달라지지 않도록 여기 한 곳에서만 그린다.
class ErrorRetryView extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const ErrorRetryView({
    super.key,
    required this.title,
    this.subtitle = '네트워크 상태를 확인한 뒤 다시 시도해 주세요',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
