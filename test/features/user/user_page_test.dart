import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/user/presentation/page/user_page.dart';

class _Auth extends AuthNotifier {
  _Auth(this.session);
  final AuthSession? session;
  @override
  Future<AuthSession?> build() async => session;
}

void main() {
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
    expect(find.text('똑똑한 학교생활을 같이 해보아요!'), findsOneWidget);
    expect(find.byTooltip('로그아웃'), findsNothing);
    expect(find.text('회원탈퇴'), findsNothing);
    // 기타: 약관 및 정책 · 앱 버전
    expect(find.text('약관 및 정책'), findsOneWidget);
    expect(find.text('v1.0.0 • 최신'), findsOneWidget);
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
    expect(find.text('정말 로그아웃하시겠어요?\n언제든 다시 로그인할 수 있어요.'), findsOneWidget);
  });
}
