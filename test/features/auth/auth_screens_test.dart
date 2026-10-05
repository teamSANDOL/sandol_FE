import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/sandol_checkbox.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/auth/presentation/widget/auth_scaffold.dart';
import 'package:handori/features/auth/screen/login_screen.dart';
import 'package:handori/features/auth/screen/signin_screen.dart';
import 'package:handori/features/home/screen/splash_screen.dart';

class _TestAuth extends AuthNotifier {
  _TestAuth([this.restoredSession]);
  final Future<AuthSession?>? restoredSession;
  @override
  Future<AuthSession?> build() => restoredSession ?? Future.value(null);
}

Finder field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);
Finder action(String label) => find.widgetWithText(FilledButton, label);

Future<void> enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(field(key));
  await tester.enterText(field(key), text);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillFirstStep(WidgetTester tester) async {
  for (final entry
      in {
        'signup-id': 'sandol',
        'signup-password': 'sandol123',
        'signup-confirmation': 'sandol123',
        'signup-email': 'sandol@example.com',
        'signup-name': '홍길동',
      }.entries) {
    await enter(tester, entry.key, entry.value);
  }
}

Future<GoRouter> host(
  WidgetTester tester, {
  String initial = RoutePaths.login,
  Size size = const Size(412, 917),
  double textScale = 1,
  Future<AuthSession?>? session,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, _) => const Splashscreen()),
      GoRoute(path: RoutePaths.login, builder: (_, _) => const Loginscreen()),
      GoRoute(
        path: RoutePaths.signIn,
        builder:
            (_, state) => Signinscreen(
              initialLanguage:
                  state.extra is AuthLanguage
                      ? state.extra as AuthLanguage
                      : AuthLanguage.ko,
            ),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(() => _TestAuth(session))],
      child: MaterialApp.router(
        theme: SandolTheme.light,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ko'), Locale('en')],
        builder:
            (context, child) => RepaintBoundary(
              key: const ValueKey('review-boundary'),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
            ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [
      SandolAssets.welcomeLogo,
      SandolAssets.loginLogo,
      SandolAssets.signupMascot,
      SandolAssets.kakao,
      SandolAssets.google,
      SandolAssets.apple,
      SandolAssets.splashPoster,
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
  return router;
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('AUTH_REVIEW')) return;
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(const ValueKey('review-boundary')),
    matchesGoldenFile('../../../.dart_tool/auth-review/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    final font =
        FontLoader('Pretendard')
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
    await font.load();
  });

  testWidgets('시작 → 아이디 입력 → 회원가입, 미연동 인증은 성공으로 처리하지 않는다', (tester) async {
    final router = await host(tester);
    await capture(tester, '01-welcome');
    await tapVisible(tester, action('아이디로 시작하기'));
    await capture(tester, '02-id-login');
    expect(tester.widget<FilledButton>(action('로그인하기')).onPressed, isNull);
    await tester.tap(find.byType(SandolCheckbox));
    await tester.pump();
    expect(
      tester.widget<SandolCheckbox>(find.byType(SandolCheckbox)).value,
      isTrue,
    );
    await enter(tester, 'login-id', 'sandol');
    await enter(tester, 'login-password', 'not-a-real-password');
    expect(
      tester.widget<TextField>(field('login-password')).obscureText,
      isTrue,
    );
    await tapVisible(tester, action('로그인하기'));
    expect(find.textContaining('웹 로그인을 이용해'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.login);
    await tester.pump(const Duration(seconds: 5));
    await tapVisible(
      tester,
      find.textContaining('계정이 없으시다면', findRichText: true),
    );
    expect(find.text('STEP 1'), findsOneWidget);
    await capture(tester, '03-signup-step1');
    expect(tester.widget<FilledButton>(action('다음으로')).onPressed, isNull);
    await fillFirstStep(tester);
    await tapVisible(tester, action('다음으로'));
    expect(find.text('STEP 2'), findsOneWidget);
    await capture(tester, '04-signup-step2');
    expect(tester.widget<FilledButton>(action('회원가입하기')).onPressed, isNull);
    await enter(tester, 'signup-nickname', '산돌친구');
    await tapVisible(tester, field('signup-birthday'));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tapVisible(tester, find.text('선택'));
    expect(
      tester.widget<TextField>(field('signup-birthday')).controller!.text,
      '2000. 01. 01.',
    );
    // 성별은 선택하지 않아도 가입 버튼이 활성화된다.
    expect(tester.widget<FilledButton>(action('회원가입하기')).onPressed, isNotNull);
    await tapVisible(tester, action('회원가입하기'));
    expect(find.textContaining('전송되지 않았어요'), findsOneWidget);
    expect(find.text('STEP 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('STEP 1'), findsOneWidget);
    expect(
      tester.widget<TextField>(field('signup-id')).controller!.text,
      'sandol',
    );
    await tapVisible(tester, action('다음으로'));
    expect(
      tester.widget<TextField>(field('signup-nickname')).controller!.text,
      '산돌친구',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('비밀번호와 이메일 검증, 단계 사이 값 보존, 언어와 성별 선택', (tester) async {
    await host(tester, initial: RoutePaths.signIn);
    await fillFirstStep(tester);
    await enter(tester, 'signup-confirmation', 'wrong');
    expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
    expect(tester.widget<FilledButton>(action('다음으로')).onPressed, isNull);
    await enter(tester, 'signup-confirmation', 'sandol123');
    await enter(tester, 'signup-email', 'missing-at.example.com');
    expect(find.text('올바른 이메일 주소를 입력해 주세요.'), findsOneWidget);
    await enter(tester, 'signup-email', 'sandol@example.com');
    await tapVisible(tester, action('다음으로'));
    await tapVisible(tester, field('signup-gender'));
    await tapVisible(tester, find.text('여성'));
    await tapVisible(tester, find.text('EN'));
    expect(
      tester.widget<TextField>(field('signup-gender')).controller!.text,
      'Female',
    );
    expect(find.text('Sign up'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Back'));
    expect(find.text('STEP 1'), findsOneWidget);
    expect(
      tester.widget<TextField>(field('signup-id')).controller!.text,
      'sandol',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('360×640, 2배 글씨, 키보드에서도 가입 폼과 버튼을 조작할 수 있다', (tester) async {
    await host(tester, size: const Size(360, 640), textScale: 2);
    await tapVisible(tester, action('아이디로 시작하기'));
    await capture(tester, '05-login-large-text');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await enter(tester, 'login-id', 'sandol');
    await enter(tester, 'login-password', 'password');
    await tapVisible(
      tester,
      find.textContaining('계정이 없으시다면', findRichText: true),
    );
    await fillFirstStep(tester);
    await tapVisible(tester, action('다음으로'));
    await enter(tester, 'signup-nickname', '산돌친구');
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    await tapVisible(tester, field('signup-gender'));
    await tapVisible(tester, find.text('선택 안 함'));
    await tester.ensureVisible(action('회원가입하기'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('아이디 화면의 시스템 뒤로가기는 시작 화면으로 돌아간다', (tester) async {
    await host(tester);
    await tapVisible(tester, action('아이디로 시작하기'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(action('아이디로 시작하기'), findsOneWidget);
    await tapVisible(tester, find.text('로그인 없이 둘러보기'));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('스플래시는 원본 비율을 유지하고 세션 복원을 기다린다', (tester) async {
    final restored = Completer<AuthSession?>();
    final router = await host(
      tester,
      initial: RoutePaths.splash,
      session: restored.future,
    );
    await capture(tester, '00-splash');
    final image = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == SandolAssets.splashPoster,
    );
    expect(tester.getSize(image).aspectRatio, closeTo(412 / 733, .001));
    await tester.pump(const Duration(seconds: 3));
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.splash);
    restored.complete(const AuthSession(accessToken: 'test-only'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
