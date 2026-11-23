import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handol/core/router/route_paths.dart';
import 'package:handol/core/utils/keep_all.dart';
import 'package:handol/features/auth/domain/model/auth_session.dart';
import 'package:handol/features/auth/presentation/provider/auth_provider.dart';
import 'package:handol/features/user/presentation/page/user_page.dart';
import 'package:handol/features/user/presentation/provider/notification_settings_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Auth extends AuthNotifier {
  _Auth(this.session);
  final AuthSession? session;
  @override
  Future<AuthSession?> build() async => session;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'handori',
      packageName: 'app.handol.student',
      version: '0.3.15',
      buildNumber: '3015',
      buildSignature: '',
    );
  });

  Future<GoRouter> pump(WidgetTester tester, AuthSession? session) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: RoutePaths.user,
      routes: [
        GoRoute(path: RoutePaths.user, builder: (_, _) => const UserPage()),
        GoRoute(
          path: RoutePaths.login,
          builder: (_, _) => const Text('login screen'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => _Auth(session))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('둘러보기(비로그인): 로그인하기 카드, 로그아웃·회원탈퇴 없음', (tester) async {
    await pump(tester, null);
    expect(find.text('로그인하기'), findsOneWidget);
    expect(find.text('똑똑한 학교생활을 같이 해보아요!'.keepAll), findsOneWidget);
    expect(find.byTooltip('로그아웃'), findsNothing);
    expect(find.text('회원탈퇴'), findsNothing);
    // 기타: 약관 및 정책 · 앱 버전
    expect(find.text('약관 및 정책'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('v0.3.15'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();
    expect(find.text('login screen'), findsOneWidget);
  });

  testWidgets('로그인: 프로필 카드 · 로그아웃 아이콘 · 회원탈퇴, 토글 전환', (tester) async {
    await pump(
      tester,
      const AuthSession(
        accessToken: 'token',
        username: 'sandori',
        email: 'sandori@gmail.com',
      ),
    );
    expect(find.text('sandori'), findsOneWidget);
    expect(find.text('sandori@gmail.com'), findsOneWidget);
    expect(find.byTooltip('로그아웃'), findsOneWidget);
    expect(find.text('회원탈퇴'), findsOneWidget);
    expect(find.text('로그인하기'), findsNothing);

    // 마케팅 토글은 꺼진 채 시작 → 누르면 켜진다 (노브가 오른쪽으로)
    final toggle = find.ancestor(
      of: find.text('마케팅 정보 수신'),
      matching: find.byType(InkWell),
    );
    final knobBefore = tester.getTopLeft(
      find.descendant(of: toggle, matching: find.byType(DecoratedBox)).last,
    );
    await tester.tap(find.text('마케팅 정보 수신'));
    await tester.pumpAndSettle();
    final knobAfter = tester.getTopLeft(
      find.descendant(of: toggle, matching: find.byType(DecoratedBox)).last,
    );
    expect(knobAfter.dx, greaterThan(knobBefore.dx));

    // 로그아웃 아이콘 → 확인 다이얼로그
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();
    expect(
      find.text('정말 로그아웃하시겠어요?\n언제든 다시 로그인할 수 있어요.'.keepAll),
      findsOneWidget,
    );
  });

  // 3버튼 바 · 제스처 바 · 바 없음: 기기가 알려 주는 높이만큼 끝을 띄운다.
  for (final navBar in [48.0, 24.0, 0.0]) {
    testWidgets('하단 여백 = 40 + 시스템 내비게이션 바($navBar)', (tester) async {
      tester.view.padding = FakeViewPadding(bottom: navBar);
      await pump(tester, null);
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.padding!.resolve(TextDirection.ltr).bottom, 40 + navBar);
    });
  }

  test('알림 설정은 앱을 다시 켜도(새 컨테이너) 남아 있다', () async {
    final c1 = ProviderContainer();
    expect(c1.read(notificationSettingsProvider).marketing, isFalse);
    final n = c1.read(notificationSettingsProvider.notifier);
    await n.setMarketing(true);
    await n.setPush(false);
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(notificationSettingsProvider);
    await Future<void>.delayed(Duration.zero);
    final s = c2.read(notificationSettingsProvider);
    expect(s.marketing, isTrue);
    expect(s.push, isFalse);
    expect(s.benefit, isTrue);
  });
}
