abstract class RoutePaths {
  // ── 셸 밖 (바텀네비 없음) ────────────────────────────────────
  static const splash = '/';
  static const login = '/login';
  static const signIn = '/sign-in';
  static const user = '/user';
  static const withdraw = '/user/withdraw';
  static const withdrawConfirm = '/user/withdraw/confirm';

  // ── 탭 브랜치 루트 ──────────────────────────────────────────
  // 순서가 AppBottomNav 인덱스와 일치한다.
  static const home = '/home'; // 0 (기본 탭)
  static const meal = '/meal'; // 1
  static const bus = '/bus'; // 2
  static const notice = '/notice'; // 3
  static const emptyClass = '/empty-class'; // 4

  // ── 탭 하위 상세 ────────────────────────────────────────────
  // 각 탭 브랜치 안에 있어 진입해도 바텀네비가 유지된다.
  static const noticeDetail = '/notice/detail';
  static const organization = '/home/organization';
  static const organizationSearch = '/home/organization/search';
}
