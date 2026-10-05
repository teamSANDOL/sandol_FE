import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 아이콘 + 글자 한 줄. 시계 · 정류장 · 출발 시각 · 안내 줄이 모두 이 모양이다.
class SandolIconLabel extends StatelessWidget {
  const SandolIconLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.style,
    this.gap = SandolSpacing.sm,
  });

  /// ⓘ + 흐린 캡션. 보조 안내 문구에 쓴다.
  factory SandolIconLabel.note(String text, {Key? key}) => SandolIconLabel(
    key: key,
    icon: SvgPicture.asset(SandolAssets.info),
    label: text,
    style: SandolTypography.caption.muted,
    gap: 6,
  );

  final Widget icon;
  final String label;
  final TextStyle style;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      SizedBox(width: gap),
      Flexible(
        child: Text(
          label,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// 셰브런. 시안 에셋은 왼쪽을 향해 있어 기본은 뒤집어 오른쪽을 가리킨다.
class SandolChevron extends StatelessWidget {
  const SandolChevron({super.key, this.muted = false, this.quarterTurns = 2});

  /// 아래를 가리키는 셰브런 (펼치기)
  static const int down = 3;

  final bool muted;

  /// 왼쪽 기준 시계 방향 90° 회전 수. 2 = 오른쪽, [down] = 아래.
  final int quarterTurns;

  @override
  Widget build(BuildContext context) => RotatedBox(
    quarterTurns: quarterTurns,
    child: SvgPicture.asset(
      muted ? SandolAssets.chevronMuted : SandolAssets.chevron,
    ),
  );
}
