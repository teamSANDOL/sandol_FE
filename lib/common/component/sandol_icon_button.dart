import 'package:flutter/material.dart';

/// 원형 아이콘 버튼.
///
/// 시안 SVG에 원형 배경이 이미 들어 있으면 [background]를 비워 둔다.
/// 높이와 너비가 조금 다른 SVG(33×34.6)도 모서리가 맞도록 Stadium으로 자른다.
class SandolIconButton extends StatelessWidget {
  const SandolIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.background = Colors.transparent,
    this.size,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color background;

  /// 배경 원의 지름. null이면 아이콘 크기를 따른다.
  final double? size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: background,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(dimension: size, child: Center(child: icon)),
      ),
    ),
  );
}
