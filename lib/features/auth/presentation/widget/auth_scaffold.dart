import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_brand.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

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

class AuthBrandHeading extends StatelessWidget {
  const AuthBrandHeading({super.key, required this.spans});
  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SandolBrand(),
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

void showAuthNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
