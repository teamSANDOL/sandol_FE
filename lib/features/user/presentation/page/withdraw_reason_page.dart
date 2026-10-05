import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/user/presentation/widget/withdraw_actions.dart';

/// 회원탈퇴 1단계: 이유 선택 (Figma 2196:800).
///
/// 이유를 고르면 그 아래 자유 의견 칸이 펼쳐진다. 아직 이유를 받는 API가
/// 없어 선택 내용은 다음 단계로 넘기기만 한다.
class WithdrawReasonPage extends StatefulWidget {
  const WithdrawReasonPage({super.key});

  static const reasons = [
    '앱 사용이 불편해요',
    '타 어플이 더 편해요(ex. tukorea portal)',
    '쓰지 않는 앱이에요',
    '재가입할 거예요',
    '기타',
  ];

  @override
  State<WithdrawReasonPage> createState() => _WithdrawReasonPageState();
}

class _WithdrawReasonPageState extends State<WithdrawReasonPage> {
  int? _selected;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

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
    body: Stack(
      children: [
        const SandolBottomGlow(),
        ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            SandolMetrics.pageGutter,
            0,
            SandolMetrics.pageGutter,
            SandolSpacing.xl,
          ),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 11),
              child: Text('탈퇴하는 이유를 알려주세요', style: SandolTypography.headline),
            ),
            const SizedBox(height: 27),
            for (var i = 0; i < WithdrawReasonPage.reasons.length; i++)
              _ReasonOption(
                label: WithdrawReasonPage.reasons[i],
                selected: _selected == i,
                onTap: () => setState(() => _selected = i),
                // 고른 이유 아래에만 의견 칸을 둔다.
                child:
                    _selected == i ? _CommentField(controller: _comment) : null,
              ),
            const SizedBox(height: 11),
            WithdrawActions(
              confirmLabel: '다음 단계로',
              onContinue: () => context.pop(),
              onConfirm:
                  _selected == null
                      ? null
                      : () => context.push(RoutePaths.withdrawConfirm),
            ),
          ],
        ),
      ],
    ),
  );
}

/// 라디오 한 줄. 선택되면 테두리와 점이 primary, 글씨가 굵어진다.
class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        borderRadius: SandolMetrics.radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: SandolColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        selected ? SandolColors.primary : SandolColors.border,
                  ),
                ),
                child: SizedBox.square(
                  dimension: 24,
                  child:
                      selected
                          ? const Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: SandolColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(dimension: 12),
                            ),
                          )
                          : null,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style:
                      selected
                          ? SandolTypography.body.strong
                          : SandolTypography.body.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      if (child != null)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
    ],
  );
}

/// 자유 의견 (2196:1131)
class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SandolCard(
    padding: const EdgeInsets.fromLTRB(44, 17, SandolMetrics.cardInset, 17),
    child: TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      style: SandolTypography.caption,
      decoration: InputDecoration.collapsed(
        hintText: '더 나은 산돌이가 될 수 있도록 의견을 들려주세요.',
        hintStyle: SandolTypography.caption.muted,
      ),
    ),
  );
}
