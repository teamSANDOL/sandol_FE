import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/coming_soon_snackbar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_button.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/constants/api_constants.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/core/utils/external_link.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/user/presentation/widget/confirm_dialog.dart';

/// 마이페이지 (Figma 2158:997).
///
/// 로그인 상태면 프로필 카드와 오른쪽 위 로그아웃, 둘러보기(비로그인)면
/// '로그인하기' 카드(2195:462)를 보여준다. 로그아웃·회원탈퇴는 실제 Keycloak
/// 세션/계정에 반영된다. 알림 토글은 서버 연동 전이라 화면 내 상태만 유지한다.
class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  bool _pushEnabled = true;
  bool _benefitEnabled = true;
  bool _marketingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authNotifierProvider).valueOrNull;
    final loggedIn = session != null;

    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '마이페이지',
        titleWidget: const Text('마이페이지', style: SandolTypography.title),
        backIcon: SvgPicture.asset(SandolAssets.backArrow),
        onBack: () => context.pop(),
        showUser: false,
        trailing:
            loggedIn
                ? SandolIconButton(
                  tooltip: '로그아웃',
                  size: 44,
                  onTap: _confirmLogout,
                  icon: SvgPicture.asset(SandolAssets.myLogout),
                )
                : null,
        backgroundColor: SandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: SandolMetrics.pageGutter - 10,
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          ListView(
            padding: const EdgeInsets.fromLTRB(
              SandolMetrics.pageGutter,
              SandolSpacing.md,
              SandolMetrics.pageGutter,
              SandolSpacing.xl,
            ),
            children: [
              if (loggedIn)
                _ProfileCard(
                  name: session.displayId,
                  email: session.email ?? session.username ?? '',
                )
              else
                _LoginCard(onTap: () => context.go(RoutePaths.login)),
              const SizedBox(height: SandolSpacing.md),
              _Section(
                label: '알림 설정',
                children: [
                  _ToggleRow(
                    icon: SandolAssets.myBell,
                    label: '푸시 알림',
                    value: _pushEnabled,
                    onChanged: (v) => setState(() => _pushEnabled = v),
                  ),
                  _ToggleRow(
                    icon: SandolAssets.myGift,
                    label: '혜택 • 이벤트 알림',
                    value: _benefitEnabled,
                    onChanged: (v) => setState(() => _benefitEnabled = v),
                  ),
                  _ToggleRow(
                    icon: SandolAssets.myMegaphone,
                    label: '마케팅 정보 수신',
                    value: _marketingEnabled,
                    onChanged: (v) => setState(() => _marketingEnabled = v),
                  ),
                ],
              ),
              const SizedBox(height: SandolSpacing.lg),
              _Section(
                label: '고객 지원',
                children: [
                  _LinkRow(
                    icon: SandolAssets.myNotice,
                    label: '공지사항',
                    onTap: () => context.go(RoutePaths.notice),
                  ),
                  _LinkRow(
                    icon: SandolAssets.myFaq,
                    label: '자주 묻는 질문',
                    onTap: () => showComingSoonSnackBar(context),
                  ),
                  _LinkRow(
                    icon: SandolAssets.myInquiry,
                    label: '1:1 문의',
                    onTap: () => showComingSoonSnackBar(context),
                  ),
                  _LinkRow(
                    icon: SandolAssets.myInfo,
                    label: '서비스 안내',
                    onTap: () => showComingSoonSnackBar(context),
                  ),
                ],
              ),
              const SizedBox(height: SandolSpacing.lg),
              _Section(
                label: '기타',
                children: [
                  _LinkRow(
                    icon: SandolAssets.myTerms,
                    label: '약관 및 정책',
                    onTap:
                        () => openExternalLink(
                          context,
                          ApiConstants.privacyPolicyUrl,
                        ),
                  ),
                  const _LinkRow(
                    icon: SandolAssets.myVersion,
                    label: '앱 버전',
                    // pubspec.yaml version 과 함께 갱신한다.
                    trailingText: 'v1.0.0 • 최신',
                  ),
                  // 비로그인(게스트)에게는 지울 계정이 없다.
                  if (loggedIn)
                    _LinkRow(
                      icon: SandolAssets.myLeave,
                      label: '회원탈퇴',
                      labelColor: SandolColors.red,
                      onTap: () => context.push(RoutePaths.withdraw),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 로그아웃 ──────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .5),
      builder:
          (context) => const ConfirmDialog(
            icon: Icons.logout_rounded,
            title: '로그아웃',
            message: '정말 로그아웃하시겠어요?\n언제든 다시 로그인할 수 있어요.',
            confirmLabel: '로그아웃',
          ),
    );
    if (confirmed != true || !mounted) return;

    await runBlocking(
      context,
      () => ref.read(authNotifierProvider.notifier).logout(),
    );
    if (!mounted) return;
    context.go(RoutePaths.login);
  }
}

// ── 프로필 카드 (2158:1014) ──────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) => SandolCard(
    padding: const EdgeInsets.symmetric(
      horizontal: SandolMetrics.cardInset,
      vertical: 32,
    ),
    child: Row(
      spacing: SandolSpacing.md,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: SandolColors.textSecondary,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 52,
            child: Center(child: SvgPicture.asset(SandolAssets.myAvatar)),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SandolSpacing.sm,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SandolTypography.title.accent,
              ),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SandolTypography.body.muted,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── 로그인하기 카드 (2195:462, 둘러보기 중) ──────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SandolCard(
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(25, 36, SandolMetrics.cardInset, 36),
    child: Row(
      spacing: 26,
      children: [
        SvgPicture.asset(SandolAssets.myLoginMascot),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Row(
                spacing: SandolSpacing.xs,
                children: [
                  Text('로그인하기', style: SandolTypography.title.accent),
                  const SandolChevron(),
                ],
              ),
              Text('똑똑한 학교생활을 같이 해보아요!', style: SandolTypography.body.muted),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── 섹션 (라벨 + 카드) ───────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: SandolSpacing.sm,
    children: [
      Text(label, style: SandolTypography.caption),
      SandolCard(
        padding: const EdgeInsets.symmetric(
          horizontal: SandolMetrics.cardInset,
          vertical: SandolSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

/// 아이콘 + 라벨 줄. 시안의 줄 간격 28을 위아래 터치 여백 12로 나눠 갖는다.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.trailing,
    this.labelColor = SandolColors.text,
    this.onTap,
  });

  final String icon;
  final String label;
  final Widget trailing;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: SandolMetrics.radius,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SandolIconLabel(
              icon: SizedBox.square(
                dimension: 26,
                child: Center(child: SvgPicture.asset(icon)),
              ),
              label: label,
              style: SandolTypography.headline.copyWith(color: labelColor),
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
    icon: icon,
    label: label,
    onTap: () => onChanged(!value),
    trailing: _Toggle(value: value),
  );
}

/// 70×32 알약 + 29×30 흰 노브 (2196:552)
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 70,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: value ? SandolColors.primary : SandolColors.text20,
      borderRadius: BorderRadius.circular(24),
    ),
    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
    child: const SizedBox(
      width: 29,
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    this.labelColor = SandolColors.text,
    this.trailingText,
    this.onTap,
  });

  final String icon;
  final String label;
  final Color labelColor;

  /// 셰브런 대신 오른쪽에 적을 글(앱 버전)
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Row(
    icon: icon,
    label: label,
    labelColor: labelColor,
    onTap: onTap,
    trailing: switch (trailingText) {
      final String text => Text(text, style: SandolTypography.caption.muted),
      null => const SandolChevron(muted: true),
    },
  );
}
