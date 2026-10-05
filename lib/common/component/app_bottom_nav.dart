import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 하단 네비 (Figma 2086:23).
///
/// 항목 순서는 [RootShell]의 브랜치 인덱스·라우터 브랜치 순서와 같아야 한다.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    required this.onTap,
    required this.currentIndex,
    super.key,
  });

  static const double _height = 70;

  /// [activeIcon]이 없으면 [icon]을 primary로 칠해 선택 상태를 나타낸다.
  static const _items = [
    (
      label: '홈',
      icon: SandolAssets.navHome,
      activeIcon: SandolAssets.navHomeActive,
    ),
    (label: '학식', icon: SandolAssets.navMeal, activeIcon: null),
    (label: '셔틀버스', icon: SandolAssets.navBus, activeIcon: null),
    (label: '공지사항', icon: SandolAssets.navNotice, activeIcon: null),
    (label: '빈 강의실', icon: SandolAssets.navEmptyClass, activeIcon: null),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SandolColors.background,
        borderRadius: SandolMetrics.radiusTop,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    label: _items[i].label,
                    icon: _items[i].icon,
                    activeIcon: _items[i].activeIcon,
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  /// 아이콘마다 높이가 달라(18.8~24) 이 칸 안에 가운데 맞춰 라벨 줄을 맞춘다.
  static const double _iconBox = 24;

  final String label;
  final String icon;
  final String? activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glyph = switch ((selected, activeIcon)) {
      (true, final String active) => SvgPicture.asset(active),
      (true, null) => SvgPicture.asset(
        icon,
        colorFilter: const ColorFilter.mode(
          SandolColors.primary,
          BlendMode.srcIn,
        ),
      ),
      _ => SvgPicture.asset(icon),
    };

    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 13),
          child: Column(
            children: [
              SizedBox(height: _iconBox, child: Center(child: glyph)),
              const SizedBox(height: SandolSpacing.xs),
              Text(
                label,
                maxLines: 1,
                style:
                    selected
                        ? SandolTypography.caption.strong.accent
                        : SandolTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
