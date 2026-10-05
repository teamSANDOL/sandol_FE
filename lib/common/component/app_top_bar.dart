import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/router/route_paths.dart';

/// 앱 전체 공통 상단 바.
///
/// 탭 화면마다 제각각이던 커스텀 앱바(홈 `TopBar`, 학식 `SliverAppBar`,
/// 공지 `AppBar`, 버스 `_Header`)를 하나로 통일한다.
///
/// - [onBack]이 null이면 뒤로가기 버튼을 그리지 않는다(홈 탭).
/// - [onBell]이 null이면 알림 아이콘을 감춘다.
/// - 유저 아이콘은 기본으로 표시되며 누르면 유저 상세(`/user`)로 이동한다.
///   [onUser]로 동작을 바꾸거나 [showUser]=false 로 감출 수 있다(유저 상세 자신).
/// - [bottom]으로 TabBar 등을 덧붙일 수 있다(공지 탭).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 툴바 높이. 화면 간 세로 리듬을 맞추기 위해 모든 탭이 공유한다.
  static const double barHeight = 56;

  /// 본문 배경과 같은 값이라 스크롤 시 경계가 생기지 않는다.
  static const Color background = AppColors.background;
  static const Color foreground = AppColors.textPrimary;

  final String title;

  /// 제목 자리에 텍스트 대신 그릴 위젯(홈 탭의 로고 이미지 등).
  final Widget? titleWidget;
  final VoidCallback? onBack;

  /// 뒤로가기 아이콘. 새 디자인 화면은 시안 SVG(SandolAssets.backArrow)를 넘긴다.
  final Widget? backIcon;
  final VoidCallback? onBell;

  /// 새로고침 아이콘 탭 동작. null 이면 아이콘을 감춘다.
  final VoidCallback? onRefresh;

  /// 유저 아이콘 탭 동작. null 이면 `/user` 로 push 한다.
  final VoidCallback? onUser;

  /// 유저 아이콘 표시 여부. 유저 상세 화면처럼 자기 자신으로 가는 아이콘이
  /// 무의미한 곳에서만 false 로 둔다.
  final bool showUser;

  /// 유저 아이콘 자리에 두는 다른 액션(마이페이지의 로그아웃 등).
  final Widget? trailing;
  final PreferredSizeWidget? bottom;

  /// 바 외곽선. 공지 탭처럼 바와 탭을 한 판으로 묶어 테두리를 두를 때 넘긴다.
  final ShapeBorder? shape;

  /// 바 배경. 새 디자인 화면은 본문 배경(SandolColors.background)을 넘긴다.
  final Color backgroundColor;

  /// 바 좌우 바깥 여백. 본문 여백이 다른 화면이 제목·아이콘을 본문에 맞춘다.
  final double horizontalPadding;

  const AppTopBar({
    required this.title,
    this.titleWidget,
    this.onBack,
    this.backIcon,
    this.onBell,
    this.onRefresh,
    this.onUser,
    this.showUser = true,
    this.trailing,
    this.bottom,
    this.shape,
    this.backgroundColor = background,
    this.horizontalPadding = 8,
    super.key,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      shape: shape,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: barHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            if (onBack != null)
              _BarIconButton(
                icon:
                    backIcon ??
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: foreground,
                    ),
                tooltip: '뒤로',
                onTap: onBack!,
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    titleWidget ??
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title02.copyWith(color: foreground),
                    ),
              ),
            ),
            if (onRefresh != null)
              _BarIconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 24,
                  color: foreground,
                ),
                tooltip: '새로고침',
                onTap: onRefresh!,
              ),
            if (onBell != null)
              _BarIconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: foreground,
                ),
                tooltip: '알림',
                onTap: onBell!,
              ),
            if (showUser)
              _BarIconButton(
                icon: SvgPicture.asset(SandolAssets.user),
                tooltip: '내 정보',
                onTap: onUser ?? () => context.push(RoutePaths.user),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
      bottom: bottom,
    );
  }
}

/// 상단 바 전용 아이콘 버튼. 터치 영역을 44x44로 보장한다.
class _BarIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
        ),
      ),
    );
  }
}
