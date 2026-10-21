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
import 'package:handori/features/auth/screen/login_screen.dart';
import 'package:handori/features/home/screen/splash_screen.dart';

/// 브라우저 로그인 대신 호출 인자만 기록한다.
final logins = <({bool kakao, bool signUp, bool rememberMe})>[];

class _TestAuth extends AuthNotifier {
  _TestAuth([this.restoredSession]);
  final Future<AuthSession?>? restoredSession;
  @override
  Future<AuthSession?> build() => restoredSession ?? Future.value(null);

  @override
  Future<bool> login({
    bool useKakao = false,
    bool signUp = false,
    bool rememberMe = true,
  }) async {
    logins.add((kakao: useKakao, signUp: signUp, rememberMe: rememberMe));
    return false;
  }
}

Finder action(String label) => find.widgetWithText(FilledButton, label);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
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

  setUp(logins.clear);

  testWidgets('앱은 비밀번호를 받지 않고 모든 로그인·가입을 브라우저로 보낸다', (tester) async {
    final router = await host(tester);
    await capture(tester, '01-welcome');
    expect(find.byType(TextField), findsNothing);
    await tapVisible(tester, action('아이디로 시작하기'));
    await tapVisible(tester, find.byTooltip('카카오로 로그인'));
    await tapVisible(
      tester,
      find.textContaining('계정이 없으시다면', findRichText: true),
    );
    expect(logins, [
      (kakao: false, signUp: false, rememberMe: true),
      (kakao: true, signUp: false, rememberMe: true),
      (kakao: false, signUp: true, rememberMe: true),
    ]);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.login);
    await tapVisible(tester, find.text('로그인 없이 둘러보기'));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('로그인 상태 유지는 기본 켬, 끄면 의미를 안내하고 그대로 전달한다', (tester) async {
    await host(tester);
    expect(
      tester.widget<SandolCheckbox>(find.byType(SandolCheckbox)).value,
      isTrue,
    );
    expect(find.text('앱을 다시 열어도 로그인이 유지돼요.'), findsOneWidget);
    await tapVisible(tester, find.byType(SandolCheckbox));
    expect(find.text('앱을 완전히 종료하면 로그아웃돼요.'), findsOneWidget);
    await tapVisible(tester, action('아이디로 시작하기'));
    await tapVisible(tester, find.byTooltip('카카오로 로그인'));
    expect(logins.map((l) => l.rememberMe), [false, false]);
  });

  testWidgets('360×640, 2배 글씨에서도 버튼을 조작할 수 있다', (tester) async {
    await host(tester, size: const Size(360, 640), textScale: 2);
    await capture(tester, '05-login-large-text');
    await tapVisible(tester, find.byType(SandolCheckbox));
    await tapVisible(
      tester,
      find.textContaining('계정이 없으시다면', findRichText: true),
    );
    expect(logins.single.signUp, isTrue);
    expect(tester.takeException(), isNull);
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
