abstract class ApiConstants {
  static const String baseUrl = 'https://sandori.kr';
  static const String staticInfoBaseUrl = 'https://sandori.kr';

  /// 학식(Meal) 서비스. host:port만 지정하고 경로에 `/meal` 접두사를 포함한다.
  /// (static-info와 동일 규칙 — baseUrl에 path를 넣으면 Dio가 leading `/`를
  ///  절대경로로 처리해 경로가 소실됨)
  static const String mealBaseUrl = 'https://sandori.kr';

  static const int defaultPageSize = 10;

  // ── 인증 (Keycloak OIDC) ────────────────────────────────────────────────
  /// Keycloak realm issuer. 로컬 테스트 시 .env 의 AUTH_ISSUER 로 오버라이드.
  static const String authIssuer = 'https://sandori.kr/auth/realms/Sandori';

  /// Keycloak 에 등록된 앱 전용 public client (PKCE 필수).
  static const String authClientId = 'handori-app';

  /// 로그인 후 앱으로 돌아오는 딥링크. 커스텀 스킴은
  /// Android(build.gradle.kts appAuthRedirectScheme)와
  /// iOS(Info.plist CFBundleURLTypes)에도 동일하게 등록되어 있다.
  static const String authRedirectUri = 'kr.sandori.handori://oauthredirect';

  // ── 정책 문서 (Google Play 필수) ───────────────────────────────────────
  /// 개인정보처리방침. Play Console 의 정책 URL 과 동일해야 하며, 원본은
  /// 저장소 docs/privacy-policy.html 이다.
  static const String privacyPolicyUrl = 'https://sandori.kr/privacy';

  /// 계정 삭제 요청 페이지(웹). 앱 내 탈퇴와 별개로 Play 정책이 요구한다.
  /// 원본은 docs/account-deletion.html.
  static const String accountDeletionUrl =
      'https://sandori.kr/account-deletion';
}
