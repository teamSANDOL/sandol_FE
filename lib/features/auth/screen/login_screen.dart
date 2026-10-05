import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/sandol_brand.dart';
import 'package:handori/common/component/sandol_button.dart';
import 'package:handori/common/component/sandol_checkbox.dart';
import 'package:handori/common/component/sandol_field.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/auth/presentation/widget/auth_scaffold.dart';

/// 기존 /login 진입점을 유지하며 시작 화면과 아이디 입력 화면을 표시한다.
class Loginscreen extends ConsumerStatefulWidget {
  const Loginscreen({super.key});
  @override
  ConsumerState<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends ConsumerState<Loginscreen> {
  bool _idLogin = false;
  bool _rememberMe = false;
  AuthLanguage _language = AuthLanguage.ko;
  final _id = TextEditingController();
  final _password = TextEditingController();
  String _text(String ko, String en) => _language.text(ko, en);

  @override
  void initState() {
    super.initState();
    _id.addListener(_update);
    _password.addListener(_update);
  }

  void _update() => setState(() {});
  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    _password.clear();
    setState(() => _idLogin = false);
  }

  Future<void> _login({required bool kakao}) async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(useKakao: kakao);
    if (success && mounted) context.go(RoutePaths.home);
  }

  void _submitCredentials() {
    if (_id.text.trim().isEmpty || _password.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    // AuthRepository는 OIDC 브라우저 인증만 지원한다. 입력값을 무시한 채
    // 성공 처리하거나 토큰 엔드포인트에 비밀번호를 전송하지 않는다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            '앱 내 아이디 로그인은 준비 중이에요. 웹 로그인을 이용해 주세요.',
            'In-app sign-in is not available yet. Please use web sign-in.',
          ),
        ),
        action: SnackBarAction(
          label: _text('웹 로그인', 'Web sign-in'),
          onPressed: () {
            _password.clear();
            _login(kakao: false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        showAuthNotice(
          context,
          _text(
            '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.',
            'Sign-in failed. Please try again.',
          ),
        );
      }
    });
    final auth = ref.watch(authNotifierProvider);
    final session = auth.valueOrNull;
    final busy = auth.isLoading;
    return PopScope(
      canPop: !_idLogin,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _idLogin) _back();
      },
      child: AuthScaffold(
        key: ValueKey(_idLogin),
        top:
            _idLogin
                ? 86
                : math.max(
                  64,
                  math.min(244, MediaQuery.sizeOf(context).height * 244 / 917),
                ),
        child:
            _idLogin
                ? _buildIdLogin(busy)
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthBrandHeading(
                      spans: [
                        TextSpan(text: _text('로그인하고 더 ', 'Sign in for a ')),
                        TextSpan(
                          text: _text('똑똑한\n학교생활', 'smarter\ncampus life'),
                          style: SandolTypography.titleAccent,
                        ),
                        TextSpan(text: _text('을 시작해요', '')),
                      ],
                    ),
                    const SizedBox(height: 92),
                    if (session == null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            asset: SandolAssets.kakao,
                            label: _text('카카오로 로그인', 'Sign in with Kakao'),
                            onPressed: busy ? null : () => _login(kakao: true),
                          ),
                          const SizedBox(width: SandolSpacing.md),
                          _SocialButton(
                            asset: SandolAssets.google,
                            label: _text('Google로 로그인', 'Sign in with Google'),
                            onPressed:
                                busy
                                    ? null
                                    : () => showAuthNotice(
                                      context,
                                      _text(
                                        'Google 로그인은 준비 중이에요.',
                                        'Google sign-in is coming soon.',
                                      ),
                                    ),
                          ),
                          const SizedBox(width: SandolSpacing.md),
                          _SocialButton(
                            asset: SandolAssets.apple,
                            label: _text('Apple로 로그인', 'Sign in with Apple'),
                            onPressed:
                                busy
                                    ? null
                                    : () => showAuthNotice(
                                      context,
                                      _text(
                                        'Apple 로그인은 준비 중이에요.',
                                        'Apple sign-in is coming soon.',
                                      ),
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AuthDivider(label: _text('또는', 'or')),
                      const SizedBox(height: SandolSpacing.sm),
                      SandolButton(
                        label: _text('아이디로 시작하기', 'Continue with ID'),
                        loading: busy,
                        onPressed: () => setState(() => _idLogin = true),
                      ),
                      const SizedBox(height: 12),
                      _TextAction(
                        label: _text('로그인 없이 둘러보기', 'Continue as a guest'),
                        onPressed:
                            busy ? null : () => context.go(RoutePaths.home),
                      ),
                    ] else ...[
                      SandolButton(
                        label: _text('홈으로 가기', 'Go to home'),
                        onPressed: () => context.go(RoutePaths.home),
                      ),
                      const SizedBox(height: 12),
                      _TextAction(
                        label: _text('로그아웃', 'Sign out'),
                        onPressed:
                            () =>
                                ref
                                    .read(authNotifierProvider.notifier)
                                    .logout(),
                      ),
                    ],
                  ],
                ),
      ),
    );
  }

  Widget _buildIdLogin(bool busy) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthHeader(
        onBack: _back,
        language: _language,
        onLanguageChanged: (language) => setState(() => _language = language),
      ),
      const SizedBox(height: 14),
      AuthBrandHeading(
        variant: SandolBrandVariant.login,
        spans: [
          TextSpan(text: _text('쉽게 로그인하고\n', 'Sign in easily\n')),
          TextSpan(
            text: _text('다양한 서비스를 이용해봐요', 'and explore our services'),
            style: SandolTypography.titleAccent,
          ),
        ],
      ),
      const SizedBox(height: 76),
      AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Column(
          children: [
            SandolField(
              key: const ValueKey('login-id'),
              size: SandolFieldSize.large,
              hint: _text('아이디 또는 이메일', 'ID or email'),
              controller: _id,
              hintMuted: false,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: SandolSpacing.sm),
            SandolField(
              key: const ValueKey('login-password'),
              size: SandolFieldSize.large,
              hint: _text('비밀번호', 'Password'),
              controller: _password,
              password: true,
              hintMuted: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!busy) _submitCredentials();
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      SandolCheckbox(
        label: _text('로그인 상태 유지', 'Keep me signed in'),
        value: _rememberMe,
        onChanged: (value) => setState(() => _rememberMe = value),
      ),
      const SizedBox(height: 56),
      SandolButton(
        label: _text('로그인하기', 'Sign in'),
        loading: busy,
        onPressed:
            _id.text.trim().isNotEmpty && _password.text.isNotEmpty
                ? _submitCredentials
                : null,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          ),
          onPressed:
              busy
                  ? null
                  : () {
                    _password.clear();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.push(RoutePaths.signIn, extra: _language);
                  },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: _text('계정이 없으시다면 ', "Don't have an account? ")),
                TextSpan(
                  text: _text('회원가입하기', 'Sign up'),
                  style: SandolTypography.captionLink,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: SandolTypography.caption.copyWith(color: SandolColors.muted),
          ),
        ),
      ),
    ],
  );
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
