import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 섹션 제목 + 본문. 홈의 주요일정 · 학식 · 셔틀버스 … 이 같은 틀을 쓴다.
class SandolSection extends StatelessWidget {
  const SandolSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  /// 제목 줄 높이. 제목에 겹쳐 올리는 요소가 위치를 계산할 때 쓴다.
  static const double titleHeight = 24;

  final String title;
  final Widget child;

  /// 제목 오른쪽 끝의 작은 액션
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: titleHeight,
        child: Row(
          children: [
            Expanded(child: Text(title, style: SandolTypography.title)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
      const SizedBox(height: SandolSpacing.sm),
      child,
    ],
  );
}
