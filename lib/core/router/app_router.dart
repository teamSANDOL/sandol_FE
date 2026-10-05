import 'package:go_router/go_router.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/screen/login_screen.dart';
import 'package:handori/features/auth/screen/signin_screen.dart';
import 'package:handori/features/auth/presentation/widget/auth_scaffold.dart';
import 'package:handori/features/bus/screen/bus_time_detail_screen.dart';
import 'package:handori/features/empty_class/screen/empty_detail_screen.dart';
import 'package:handori/features/home/screen/home_screen.dart';
import 'package:handori/features/home/screen/splash_screen.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/presentation/page/notice_detail_page.dart';
import 'package:handori/features/notice/presentation/page/notice_page.dart';
import 'package:handori/features/organization/presentation/page/organization_search_page.dart';
import 'package:handori/features/organization/presentation/page/organization_tree_page.dart';
import 'package:handori/features/school_meal/presentation/page/restaurant_detail_page.dart';
import 'package:handori/features/user/presentation/page/user_page.dart';
import 'package:handori/features/user/presentation/page/withdraw_confirm_page.dart';
import 'package:handori/features/user/presentation/page/withdraw_reason_page.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    // ── 셸 밖: 스플래시 · 로그인 (바텀네비 없음) ──────────────────
    GoRoute(path: RoutePaths.splash, builder: (_, _) => const Splashscreen()),
    // 실제 계정 생성 API 연결 전까지 회원가입 제출은 안내로 처리한다.
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
    GoRoute(path: RoutePaths.login, builder: (_, _) => const Loginscreen()),
    // 유저 상세(설정): 시안대로 바텀네비 없이 전체 화면으로 띄운다.
    GoRoute(
      path: RoutePaths.user,
      builder: (_, _) => const UserPage(),
      routes: [
        // 회원탈퇴: 이유 선택 → 최종 확인
        GoRoute(
          path: 'withdraw',
          builder: (_, _) => const WithdrawReasonPage(),
          routes: [
            GoRoute(
              path: 'confirm',
              builder: (_, _) => const WithdrawConfirmPage(),
            ),
          ],
        ),
      ],
    ),

    // ── 셸: 5개 탭 ─────────────────────────────────────────────
    // 브랜치 순서가 AppBottomNav 항목 · RootShell 인덱스 상수와 일치해야 한다.
    // 상세 화면을 각 브랜치 하위에 두면 진입해도 바텀네비가 유지되고,
    // 탭을 옮겼다 돌아왔을 때 스택이 보존된다.
    StatefulShellRoute.indexedStack(
      builder:
          (_, _, navigationShell) =>
              RootShell(navigationShell: navigationShell),
      branches: [
        // 0 · 홈 (기본 탭)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'organization',
                  builder: (_, _) => const OrganizationTreePage(),
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder:
                          (_, state) => OrganizationSearchPage(
                            query: state.extra as String? ?? '',
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // 1 · 학식
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.meal,
              builder: (_, _) => const RestaurantDetailPage(),
            ),
          ],
        ),

        // 2 · 셔틀버스
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.bus,
              builder: (_, _) => const BusTimeDetailScreen(),
            ),
          ],
        ),

        // 3 · 공지사항
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.notice,
              builder: (_, _) => const NoticePage(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder:
                      (_, state) =>
                          NoticeDetailPage(notice: state.extra as Notice),
                ),
              ],
            ),
          ],
        ),

        // 4 · 빈 강의실
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.emptyClass,
              builder: (_, _) => const EmptyDetailScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
