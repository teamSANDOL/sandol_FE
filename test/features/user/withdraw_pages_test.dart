import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/user/presentation/page/withdraw_confirm_page.dart';
import 'package:handori/features/user/presentation/page/withdraw_reason_page.dart';

class _Auth extends AuthNotifier {
  int deleted = 0;
  @override
  Future<AuthSession?> build() async =>
      const AuthSession(accessToken: 't', username: 'u');
  @override
  Future<void> deleteAccount() async {
    deleted++;
    state = const AsyncData(null);
  }
}

void main() {
  late _Auth auth;

  Future<void> pump(WidgetTester tester, String initial) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth = _Auth();
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: RoutePaths.user,
          builder: (_, _) => const Text('my page'),
        ),
        GoRoute(
          path: RoutePaths.withdraw,
          builder: (_, _) => const WithdrawReasonPage(),
        ),
        GoRoute(
          path: RoutePaths.withdrawConfirm,
          builder: (_, _) => const WithdrawConfirmPage(),
        ),
        GoRoute(path: RoutePaths.login, builder: (_, _) => const Text('login')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) =>
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(FilledButton),
            ),
          )
          .enabled;

  testWidgets('이유 선택: 고르기 전엔 다음 단계 비활성, 고르면 의견 칸이 열리고 넘어간다', (tester) async {
    await pump(tester, RoutePaths.withdraw);
    expect(find.text('탈퇴하는 이유를 알려주세요'), findsOneWidget);
    expect(enabled(tester, '다음 단계로'), isFalse);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('타 어플이 더 편해요(ex. tukorea portal)'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(enabled(tester, '다음 단계로'), isTrue);

    await tester.tap(find.text('다음 단계로'));
    await tester.pumpAndSettle();
    expect(find.text('정말로 떠나실 건가요?'), findsOneWidget);
  });

  testWidgets('최종 확인: 동의해야 탈퇴 버튼이 켜지고, 탈퇴하면 로그인 화면으로', (tester) async {
    await pump(tester, RoutePaths.withdrawConfirm);
    expect(find.text('꼭 확인해주세요!'), findsOneWidget);
    expect(find.textContaining('30일 동안'), findsOneWidget);
    expect(enabled(tester, '회원 탈퇴하기'), isFalse);

    await tester.tap(find.text('위 내용을 숙지하였으며 탈퇴에 동의합니다.'));
    await tester.pumpAndSettle();
    expect(enabled(tester, '회원 탈퇴하기'), isTrue);

    await tester.tap(find.text('회원 탈퇴하기'));
    await tester.pumpAndSettle();
    expect(auth.deleted, 1);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('계속 사용하기는 마이페이지로 돌아간다', (tester) async {
    await pump(tester, RoutePaths.withdrawConfirm);
    await tester.tap(find.text('계속 사용하기'));
    await tester.pumpAndSettle();
    expect(find.text('my page'), findsOneWidget);
  });
}
