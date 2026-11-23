import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handol/common/component/handol_brand.dart';
import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/design_system/handol_tokens.dart';

/// 412px 시안의 33px 여백. 좁은 화면/키보드/큰 글씨는 자연스럽게 스크롤한다.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, required this.top});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Theme(
    data: HandolTheme.light,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: HandolColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: LayoutBuilder(
              builder:
                  (context, viewport) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: math.min(
                        HandolMetrics.pageGutter,
                        MediaQuery.sizeOf(context).width * .08,
                      ),
                    ),
                    // 위 여백은 시안 위치(top)까지만 쓰고, 내용이 화면보다 길면 먼저
                    // 줄여(최소 16) 아래 버튼이 내비게이션 바 밑으로 밀리지 않게 한다.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewport.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 16,
                                  maxHeight: math.max(
                                    16,
                                    top - MediaQuery.paddingOf(context).top,
                                  ),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: HandolMetrics.contentWidth,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: child,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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
      const HandolBrand(),
      const SizedBox(height: HandolSpacing.sm),
      Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: HandolTypography.title,
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
        child: SvgPicture.asset(HandolAssets.dividerLeft, fit: BoxFit.fill),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: HandolTypography.caption.copyWith(color: HandolColors.muted),
        ),
      ),
      Expanded(
        child: SvgPicture.asset(HandolAssets.dividerRight, fit: BoxFit.fill),
      ),
    ],
  );
}

void showAuthNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
