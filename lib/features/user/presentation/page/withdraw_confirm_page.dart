import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_checkbox.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/user/presentation/widget/confirm_dialog.dart';
import 'package:handori/features/user/presentation/widget/withdraw_actions.dart';

/// 회원탈퇴 2단계: 최종 확인 (Figma 2196:951).
///
/// 유의사항에 동의해야 '회원 탈퇴하기'가 켜진다. 탈퇴는 실제 Keycloak
/// 계정 삭제이며 끝나면 로그인 화면으로 보낸다.
class WithdrawConfirmPage extends ConsumerStatefulWidget {
  const WithdrawConfirmPage({super.key});

  @override
  ConsumerState<WithdrawConfirmPage> createState() =>
      _WithdrawConfirmPageState();
}

class _WithdrawConfirmPageState extends ConsumerState<WithdrawConfirmPage> {
  bool _agreed = false;

  Future<void> _deleteAccount() async {
    try {
      await runBlocking(
        context,
        () => ref.read(authNotifierProvider.notifier).deleteAccount(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원 탈퇴가 완료되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(RoutePaths.login);
    } catch (_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .5),
        builder:
            (context) => const ConfirmDialog(
              icon: Icons.error_outline_rounded,
              title: '탈퇴 실패',
              message: '계정 삭제 요청이 실패했습니다.\n잠시 후 다시 시도하거나 관리자에게 문의해 주세요.',
              confirmLabel: '확인',
              showCancel: false,
            ),
      );
    }
  }

  /// 두 단계 모두 '계속 사용하기'는 마이페이지로 돌아간다.
  void _keepUsing() => context.go(RoutePaths.user);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SandolColors.background,
    appBar: AppTopBar(
      title: '회원탈퇴',
      titleWidget: const Text('회원탈퇴', style: SandolTypography.title),
      backIcon: SvgPicture.asset(SandolAssets.backArrow),
      onBack: () => context.pop(),
      showUser: false,
      backgroundColor: SandolColors.background,
      horizontalPadding: SandolMetrics.pageGutter - 10,
    ),
    body: ListView(
      padding: const EdgeInsets.only(top: 12, bottom: SandolSpacing.xl),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SandolMetrics.pageGutter),
          child: _FarewellCard(),
        ),
        const SizedBox(height: 14),
        Text(
          '조금 더 함께하고 싶지만,\n아쉬운 마음으로 보내드릴게요. 언제든 다시 찾아주세요!',
          textAlign: TextAlign.center,
          style: SandolTypography.body,
        ),
        const SizedBox(height: 78),
        const _NoticeBlock(),
        const SizedBox(height: 9),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SandolMetrics.pageGutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SandolCheckbox(
                dense: true,
                label: '위 내용을 숙지하였으며 탈퇴에 동의합니다.',
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v),
              ),
              const SizedBox(height: 5),
              WithdrawActions(
                confirmLabel: '회원 탈퇴하기',
                onContinue: _keepUsing,
                onConfirm: _agreed ? _deleteAccount : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 진회색 카드 + 우는 산돌이 (2196:676)
class _FarewellCard extends StatelessWidget {
  const _FarewellCard();

  @override
  Widget build(BuildContext context) => SandolCard(
    color: SandolColors.textSecondary,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 23),
    child: Column(
      spacing: 9,
      children: [
        Text('정말로 떠나실 건가요?', style: SandolTypography.title.onPrimary),
        SvgPicture.asset(SandolAssets.myWithdrawMascot),
      ],
    ),
  );
}

/// 회색 띠 안의 유의사항 (2196:1183). 두 번째 항목은 빨간 글씨.
class _NoticeBlock extends StatelessWidget {
  const _NoticeBlock();

  static const _items = <(String, bool)>[
    (
      '회원탈퇴 시 산돌이의 모든 서비스 이용 내역 및 개인 계정 정보가 즉시 파기되며, 어떠한 경우에도 영구적으로 복구할 수 없습니다.',
      false,
    ),
    ('무분별한 탈퇴 및 재가입 방지를 위해 탈퇴 후 30일 동안 동일한 계정 정보로 다시 가입할 수 없습니다.', true),
    (
      '단, 관련 법령에 따라 보존할 의무가 있는 결제 및 주요 서비스 이용 기록은 정해진 기간 동안 안전하게 보관된 후 파기됩니다.',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0x1A040404),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        32,
        SandolMetrics.pageGutter,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 35,
        children: [
          SandolIconLabel(
            icon: SvgPicture.asset(SandolAssets.myNoticeInfo),
            label: '꼭 확인해주세요!',
            style: SandolTypography.body.strong,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SandolSpacing.md,
            children: [
              for (final (text, red) in _items)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SandolSpacing.sm,
                  children: [
                    Text('•', style: _style(red)),
                    Expanded(child: Text(text, style: _style(red))),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
  );

  static TextStyle _style(bool red) => SandolTypography.caption.copyWith(
    height: 18 / 14,
    letterSpacing: -1,
    color: red ? SandolColors.red : SandolColors.text,
  );
}
