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

  /// 제목 줄 최소 높이. 글꼴이 커지면 늘어난다. 제목에 겹쳐 올리는 요소는 기본 글꼴 기준으로 위치를 계산한다.
  static const double titleHeight = 24;

  final String title;
  final Widget child;

  /// 제목 오른쪽 끝의 작은 액션
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: titleHeight),
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
