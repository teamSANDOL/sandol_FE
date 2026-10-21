import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/sandol_button.dart';
import 'package:handori/common/component/sandol_checkbox.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/auth/presentation/widget/auth_scaffold.dart';

/// 로그인 시작 화면. 아이디·비밀번호는 앱에서 받지 않는다 — 로그인과
/// 회원가입은 모두 시스템 브라우저의 Keycloak 화면에서 한다.
class Loginscreen extends ConsumerStatefulWidget {
  const Loginscreen({super.key});
  @override
  ConsumerState<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends ConsumerState<Loginscreen> {
  bool _rememberMe = true;

  Future<void> _login({bool kakao = false, bool signUp = false}) async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(useKakao: kakao, signUp: signUp, rememberMe: _rememberMe);
    if (success && mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        showAuthNotice(context, '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
    });
    final auth = ref.watch(authNotifierProvider);
    final session = auth.valueOrNull;
    final busy = auth.isLoading;
    return AuthScaffold(
      top: math.max(
        64,
        math.min(244, MediaQuery.sizeOf(context).height * 244 / 917),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandHeading(
            spans: [
              TextSpan(text: '로그인하고 더 '),
              TextSpan(text: '똑똑한\n학교생활', style: SandolTypography.titleAccent),
              TextSpan(text: '을 시작해요'),
            ],
          ),
          const SizedBox(height: 92),
          if (session == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  asset: SandolAssets.kakao,
                  label: '카카오로 로그인',
                  onPressed: busy ? null : () => _login(kakao: true),
                ),
                const SizedBox(width: SandolSpacing.md),
                _SocialButton(
                  asset: SandolAssets.google,
                  label: 'Google로 로그인',
                  onPressed:
                      busy
                          ? null
                          : () =>
                              showAuthNotice(context, 'Google 로그인은 준비 중이에요.'),
                ),
                const SizedBox(width: SandolSpacing.md),
                _SocialButton(
                  asset: SandolAssets.apple,
                  label: 'Apple로 로그인',
                  onPressed:
                      busy
                          ? null
                          : () =>
                              showAuthNotice(context, 'Apple 로그인은 준비 중이에요.'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const AuthDivider(label: '또는'),
            const SizedBox(height: SandolSpacing.sm),
            SandolButton(
              label: '아이디로 시작하기',
              loading: busy,
              onPressed: () => _login(),
            ),
            const SizedBox(height: 6),
            SandolCheckbox(
              label: '로그인 상태 유지',
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value),
            ),
            Text(
              _rememberMe ? '앱을 다시 열어도 로그인이 유지돼요.' : '앱을 완전히 종료하면 로그아웃돼요.',
              style: SandolTypography.caption.copyWith(
                color: SandolColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
                onPressed: busy ? null : () => _login(signUp: true),
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: '계정이 없으시다면 '),
                      TextSpan(
                        text: '회원가입하기',
                        style: SandolTypography.captionLink,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: SandolTypography.caption.copyWith(
                    color: SandolColors.muted,
                  ),
                ),
              ),
            ),
            _TextAction(
              label: '로그인 없이 둘러보기',
              onPressed: busy ? null : () => context.go(RoutePaths.home),
            ),
          ] else ...[
            SandolButton(
              label: '홈으로 가기',
              onPressed: () => context.go(RoutePaths.home),
            ),
            const SizedBox(height: 12),
            _TextAction(
              label: '로그아웃',
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.asset,
    required this.label,
    this.onPressed,
  });
  final String asset;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onPressed != null,
    child: Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: SandolMetrics.radius,
        child: SizedBox(
          width: 46,
          height: 47,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: SandolColors.muted,
      textStyle: SandolTypography.caption,
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}
