/** 로그인된 사용자의 토큰 묶음 (Keycloak OIDC Authorization Code + PKCE) */
export type AuthSession = {
  accessToken: string;
  refreshToken?: string | null;
  idToken?: string | null;
  /** epoch ms */
  accessTokenExpiresAt?: number | null;
  /** epoch ms. 오프라인 토큰처럼 만료가 없으면 null */
  refreshTokenExpiresAt?: number | null;
  username?: string | null;
  email?: string | null;
};

/** 화면에 표시할 아이디. 이메일 로컬파트(@ 앞). 없으면 username, 그것도 없으면 '사용자' */
export function displayId(s: AuthSession): string {
  const source = s.email ? s.email : s.username;
  const local = source?.split('@')[0];
  return local ? local : '사용자';
}

function isValid(expiresAt: number | null | undefined, leewayMs: number, now: number): boolean {
  if (expiresAt == null) return true;
  return now + leewayMs < expiresAt;
}

/** 액세스 토큰이 아직 유효한지. 경계 시점 401 을 막으려 30초 여유를 둔다 */
export function isAccessTokenValid(s: AuthSession, now = Date.now(), leewayMs = 30_000): boolean {
  return isValid(s.accessTokenExpiresAt, leewayMs, now);
}

/** 리프레시 토큰이 아직 유효한지. 만료 정보가 없으면 서버 판단에 맡긴다 */
export function isRefreshTokenValid(s: AuthSession, now = Date.now(), leewayMs = 0): boolean {
  return Boolean(s.refreshToken) && isValid(s.refreshTokenExpiresAt, leewayMs, now);
}

function base64UrlDecode(input: string): string {
  const b64 = input.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(input.length / 4) * 4, '=');
  const binary = globalThis.atob(b64);
  const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

/** JWT payload (서명 검증은 리소스 서버 몫이라 하지 않는다) */
export function jwtPayload(jwt?: string | null): Record<string, unknown> | null {
  if (!jwt) return null;
  const parts = jwt.split('.');
  if (parts.length !== 3) return null;
  try {
    const parsed: unknown = JSON.parse(base64UrlDecode(parts[1]));
    return parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

/** JWT exp(ms). Keycloak 오프라인 토큰은 exp 가 없거나 0 이라 null */
export function expiryFromJwt(jwt?: string | null): number | null {
  const exp = jwtPayload(jwt)?.exp;
  return typeof exp === 'number' && exp > 0 ? exp * 1000 : null;
}

export function usernameFromJwt(jwt?: string | null): string | null {
  const p = jwtPayload(jwt);
  const v = p?.preferred_username ?? p?.name ?? p?.email;
  return typeof v === 'string' ? v : null;
}

export function emailFromJwt(jwt?: string | null): string | null {
  const v = jwtPayload(jwt)?.email;
  return typeof v === 'string' ? v : null;
}
