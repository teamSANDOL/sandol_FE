import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 화면 아래에서 번지는 푸른 광원 (Figma 2156:449 · 2156:655).
/// 홈 · 셔틀버스처럼 새 디자인 탭 화면의 body Stack 맨 아래에 둔다.
///
/// 시안은 지름 518 원(main40)에 blur 150을 준 것이다. flutter_svg가 SVG
/// 필터를 그리지 않아 코드로 옮겼다. 원 중심은 하단 네비 아래 161에 있다.
class SandolBottomGlow extends StatelessWidget {
  const SandolBottomGlow({super.key});

  static const double _diameter = 518;
  static const double _blur = 150;

  /// 본문 아래끝(= 네비 위끝)에서 원 중심까지. 네비 높이 70 + 161.
  static const double _centerBelow = 231;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: -(_centerBelow + _diameter / 2),
    height: _diameter,
    child: IgnorePointer(
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blur,
            sigmaY: _blur,
            tileMode: TileMode.decal,
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: _diameter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SandolColors.primary40,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
