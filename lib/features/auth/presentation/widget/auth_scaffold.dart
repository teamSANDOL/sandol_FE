import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_brand.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

enum AuthLanguage {
  ko,
  en;

  String text(String ko, String en) => this == AuthLanguage.ko ? ko : en;
}

/// 412px 시안의 33px 여백. 좁은 화면/키보드/큰 글씨는 자연스럽게 스크롤한다.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, required this.top});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Theme(
    data: SandolTheme.light,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: SandolColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                math.min(
                  SandolMetrics.pageGutter,
                  MediaQuery.sizeOf(context).width * .08,
                ),
                math.max(16, top - MediaQuery.paddingOf(context).top),
                math.min(
                  SandolMetrics.pageGutter,
                  MediaQuery.sizeOf(context).width * .08,
                ),
                32,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SandolMetrics.contentWidth,
                  ),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.onBack,
    required this.language,
    required this.onLanguageChanged,
    this.step,
  });
  final VoidCallback onBack;
  final AuthLanguage language;
  final ValueChanged<AuthLanguage> onLanguageChanged;
  final int? step;

  @override
  Widget build(BuildContext context) {
    final back = IconButton(
      tooltip: language.text('뒤로', 'Back'),
      onPressed: onBack,
      icon: SvgPicture.asset(SandolAssets.backArrow, width: 24, height: 24),
    );
    final languages = _LanguageControl(
      language: language,
      onChanged: onLanguageChanged,
    );
    final badge =
        step == null ? const SizedBox.shrink() : _StepBadge(step: step!);
    // 큰 글씨에서는 중앙 고정 배치 대신 순서대로 배치해 컨트롤 겹침을 막는다.
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Row(
        children: [back, Expanded(child: Center(child: badge)), languages],
      );
    }
    return SizedBox(
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(left: -12, child: back),
          if (step != null)
            Transform.translate(offset: const Offset(-3.5, 0), child: badge),
          Positioned(right: 0, child: languages),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 75),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: const BoxDecoration(
      color: SandolColors.primary,
      borderRadius: SandolMetrics.radius,
    ),
    child: Text(
      'STEP $step',
      textAlign: TextAlign.center,
      style: SandolTypography.caption.copyWith(color: SandolColors.background),
    ),
  );
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({required this.language, required this.onChanged});
  final AuthLanguage language;
  final ValueChanged<AuthLanguage> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: SandolColors.field,
      borderRadius: SandolMetrics.radius,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final value in [AuthLanguage.en, AuthLanguage.ko])
          Semantics(
            selected: language == value,
            button: true,
            label: value == AuthLanguage.en ? 'English' : '한국어',
            child: InkWell(
              borderRadius: SandolMetrics.radius,
              onTap: () => onChanged(value),
              child: Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  value.name.toUpperCase(),
                  style: SandolTypography.caption,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class AuthBrandHeading extends StatelessWidget {
  const AuthBrandHeading({
    super.key,
    required this.spans,
    this.variant = SandolBrandVariant.welcome,
  });
  final List<InlineSpan> spans;
  final SandolBrandVariant variant;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SandolBrand(variant: variant),
      const SizedBox(height: SandolSpacing.sm),
      Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: SandolTypography.title,
      ),
    ],
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SvgPicture.asset(SandolAssets.dividerLeft, fit: BoxFit.fill),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: SandolTypography.caption.copyWith(color: SandolColors.muted),
        ),
      ),
      Expanded(
        child: SvgPicture.asset(SandolAssets.dividerRight, fit: BoxFit.fill),
      ),
    ],
  );
}

class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(title, textAlign: TextAlign.center, style: SandolTypography.title),
      const SizedBox(height: SandolSpacing.md),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: SandolTypography.caption.copyWith(color: SandolColors.muted),
      ),
    ],
  );
}

void showAuthNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
