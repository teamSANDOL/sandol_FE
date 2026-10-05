import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 새 디자인의 카드 틀: 배경 + 36% 테두리 + 12 모서리 + 옅은 그림자.
///
/// 안쪽 사진·헤더 띠가 모서리를 넘지 않게 항상 잘라내고, 테두리는 그 위에
/// 그린다. 그림자는 잘리지 않도록 잘라내는 Material 바깥에 둔다.
/// [onTap]이 있으면 카드 전체가 눌린다.
class SandolCard extends StatelessWidget {
  const SandolCard({
    super.key,
    required this.child,
    this.padding,
    this.color = SandolColors.background,
    this.borderColor = SandolColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;

  /// 기본은 36% 테두리. 공지 목록처럼 primary 테두리를 쓰는 카드가 바꾼다.
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: SandolMetrics.radius,
        boxShadow: SandolShadows.card,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: SandolMetrics.radius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
