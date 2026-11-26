import Constants from 'expo-constants';

const extra = (Constants.expoConfig?.extra ?? {}) as Record<string, unknown>;

/** 비어 있지 않은 문자열만 받는다(매니페스트가 빈 값을 {} 로 바꾸는 경우를 거른다). */
function str(value: unknown): string | null {
  return typeof value === 'string' && value.trim() !== '' ? value.trim() : null;
}

/** API · 인증 상수 (Flutter ApiConstants). .env 값이 있으면 그쪽이 우선한다. */
export const env = {
  /** 일반 · 학식 · 정적 정보 API 가 모두 같은 호스트를 쓴다 */
  apiBaseUrl: str(extra.apiBaseUrl) ?? 'https://sandori.kr',
  /** 운영 서버가 못 받는 GET 을 1회 재시도할 대체 주소. 없으면 재시도 안 함 */
  apiFallbackBaseUrl: str(extra.apiFallbackBaseUrl),
  authIssuer: str(extra.authIssuer) ?? 'https://sandori.kr/auth/realms/Sandori',
  authClientId: str(extra.authClientId) ?? 'handori-app',
  authRedirectUri: 'kr.sandori.handori://oauthredirect',
  naverMapEnabled: extra.naverMapEnabled === true,
  defaultPageSize: 10,
  privacyPolicyUrl: 'https://quanect.kr/policies/sandori-service',
  termsOfServiceUrl: 'https://quanect.kr/policies/terms-of-service',
  accountDeletionUrl: 'https://sandori.kr/account-deletion',
  /** 새 설치 파일 안내. Play 출시 전까지는 Gitea 릴리스로 보낸다(Android 전용) */
  appReleasesApi: 'https://git.house.sio2.kr/api/v1/repos/Seokyoung-Hong/Handol-App/releases?limit=1&draft=false',
  appReleasePage: 'https://git.house.sio2.kr/Seokyoung-Hong/Handol-App/releases/tag/',
} as const;
