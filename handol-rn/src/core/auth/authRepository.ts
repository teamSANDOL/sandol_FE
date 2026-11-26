import * as AuthSessionLib from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import { env } from '../env';
import {
  emailFromJwt,
  expiryFromJwt,
  isAccessTokenValid,
  isRefreshTokenValid,
  usernameFromJwt,
  type AuthSession,
} from './session';
import { TokenStorage } from './tokenStorage';

/** 사용자가 브라우저를 닫는 등 로그인을 취소했다 */
export class AuthCancelledError extends Error {
  constructor() {
    super('로그인이 취소되었습니다');
    this.name = 'AuthCancelledError';
  }
}

/** 리프레시가 일시적으로 실패했다(네트워크 · 5xx). 세션은 유지된다 */
export class AuthRefreshUnavailableError extends Error {
  constructor(readonly cause: unknown) {
    super('토큰 갱신 보류');
    this.name = 'AuthRefreshUnavailableError';
  }
}

export type LoginOptions = { useKakao?: boolean; signUp?: boolean; rememberMe?: boolean };

/** offline_access: 리프레시 토큰이 SSO 유휴(30분)가 아니라 오프라인 유휴(30일)를 따른다 */
const SCOPES = ['openid', 'profile', 'email', 'offline_access'];
const SESSION_SCOPES = ['openid', 'profile', 'email'];
const RETRY_BACKOFF_MS = 15_000;
const CLOCK_SKEW_MS = 60 * 60 * 1000;
/** 다시 시도해도 풀리지 않는 OAuth 오류. 세션을 지운다 */
const PERMANENT_ERRORS = ['invalid_grant', 'invalid_scope', 'unauthorized_client', 'invalid_client', 'not_allowed', 'access_denied'];

function isPermanentRefreshError(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  if (typeof code === 'string' && PERMANENT_ERRORS.includes(code)) return true;
  const msg = e instanceof Error ? e.message : '';
  return PERMANENT_ERRORS.some((p) => msg.includes(p));
}

type Listener = (s: AuthSession | null) => void;

/**
 * Keycloak OIDC(Authorization Code + PKCE) 인증 (Flutter AuthRepositoryImpl 이식).
 * - 리프레시는 single-flight: 동시에 만료를 만나도 한 번만 나간다.
 * - invalid_grant 등 영구 오류일 때만 세션을 지우고, 네트워크 오류는 세션을 유지한 채 15초 백오프.
 * - 세대(generation): 로그인 · 로그아웃 · 탈퇴마다 올려, 늦게 온 리프레시 응답이 상태를 덮지 않게 한다.
 */
export class AuthRepository {
  private readonly issuer = env.authIssuer;
  private readonly clientId = env.authClientId;
  private readonly redirectUri = env.authRedirectUri;
  private readonly discovery = {
    authorizationEndpoint: `${env.authIssuer}/protocol/openid-connect/auth`,
    tokenEndpoint: `${env.authIssuer}/protocol/openid-connect/token`,
    revocationEndpoint: `${env.authIssuer}/protocol/openid-connect/revoke`,
    endSessionEndpoint: `${env.authIssuer}/protocol/openid-connect/logout`,
  };
  private inflight: Promise<AuthSession | null> | null = null;
  private retryNotBefore: number | null = null;
  private rememberMe = true;
  private generation = 0;
  private listeners = new Set<Listener>();

  constructor(private readonly storage = new TokenStorage()) {}

  /** 리프레시 등으로 로그인 UI 를 거치지 않고 세션이 바뀔 때 알린다 */
  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(s: AuthSession | null) {
    this.listeners.forEach((l) => l(s));
  }

  async login({ useKakao = false, signUp = false, rememberMe = true }: LoginOptions = {}): Promise<AuthSession> {
    this.generation++;
    // 로그아웃해도 Custom Tab 에는 SSO 쿠키가 남는다. 명시적 로그아웃 뒤에는 재인증을 요구한다.
    const forceLogin = await this.storage.readForceLogin();
    const request = new AuthSessionLib.AuthRequest({
      clientId: this.clientId,
      redirectUri: this.redirectUri,
      scopes: rememberMe ? SCOPES : SESSION_SCOPES,
      usePKCE: true,
      responseType: AuthSessionLib.ResponseType.Code,
      // prompt=create: Keycloak 회원가입 화면으로 바로 연다(Keycloak 18+)
      prompt: signUp
        ? ('create' as AuthSessionLib.Prompt)
        : forceLogin
          ? AuthSessionLib.Prompt.Login
          : undefined,
      // 카카오 IdP 로 직행. alias 는 대소문자 구분 — 운영 realm 에 'Kakao' 로 등록되어 있다.
      extraParams: useKakao ? { kc_idp_hint: 'Kakao' } : undefined,
    });
    const result = await request.promptAsync(this.discovery, { showInRecents: true });
    if (result.type === 'cancel' || result.type === 'dismiss' || result.type === 'locked') {
      throw new AuthCancelledError();
    }
    if (result.type !== 'success') {
      const err = result.type === 'error' ? result.error : null;
      throw new Error(err?.message ?? '로그인에 실패했습니다');
    }
    const tokens = await AuthSessionLib.exchangeCodeAsync(
      {
        clientId: this.clientId,
        code: result.params.code,
        redirectUri: this.redirectUri,
        extraParams: request.codeVerifier ? { code_verifier: request.codeVerifier } : undefined,
      },
      this.discovery,
    );
    const session = this.toSession(tokens);
    this.retryNotBefore = null;
    this.rememberMe = rememberMe;
    await this.storage.save(session, rememberMe);
    // 유지하지 않는 세션은 앱 종료로 조용히 끝나므로 로그아웃과 같이 다룬다.
    await this.storage.writeForceLogin(!rememberMe);
    return session;
  }

  /** 저장된 세션 복원. 만료면 리프레시, 일시 실패면 저장된 세션을 그대로 돌려준다 */
  async restoreSession(): Promise<AuthSession | null> {
    const saved = await this.storage.read();
    if (!saved) return null;
    if (isAccessTokenValid(saved)) return saved;
    try {
      return await this.refresh();
    } catch (e) {
      if (e instanceof AuthRefreshUnavailableError) return saved;
      throw e;
    }
  }

  /** API 호출에 쓸 유효한 토큰. 비로그인 · 일시 실패면 null */
  async getValidAccessToken(): Promise<string | null> {
    const saved = await this.storage.read();
    if (!saved) return null;
    if (isAccessTokenValid(saved)) return saved.accessToken;
    try {
      return (await this.refresh())?.accessToken ?? null;
    } catch {
      return null;
    }
  }

  async logout(): Promise<void> {
    this.generation++;
    await this.storage.writeForceLogin(true);
    const saved = await this.storage.read();
    const refreshToken = saved?.refreshToken;
    if (refreshToken) {
      // 세션 종료(/logout)가 사용자 · 오프라인 세션을 모두 끝낸다. 실패 시에만 폐기로 대체.
      try {
        await this.postForm(this.discovery.endSessionEndpoint, { client_id: this.clientId, refresh_token: refreshToken });
      } catch {
        await this.revoke(refreshToken);
      }
    }
    await this.storage.clear();
    this.generation++;
    this.retryNotBefore = null;
    // 브라우저 쿠키 세션도 정리(베스트 에포트)
    WebBrowser.coolDownAsync().catch(() => undefined);
  }

  /** Keycloak 계정 영구 삭제. 서버 삭제가 실패하면 로컬 세션은 유지한 채 예외 */
  async deleteAccount(): Promise<void> {
    this.retryNotBefore = null;
    const session = await this.restoreSession();
    this.generation++;
    if (!session) {
      await this.storage.writeForceLogin(true);
      await this.storage.clear();
      this.generation++;
      return;
    }
    if (!isAccessTokenValid(session)) {
      throw new Error('로그인 세션을 갱신하지 못해 탈퇴를 진행할 수 없습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.');
    }
    const res = await fetch(`${this.issuer}/account`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${session.accessToken}` },
    });
    if (!res.ok) throw new Error(`계정 삭제 실패 (HTTP ${res.status})`);
    await this.storage.writeForceLogin(true);
    await this.storage.clear();
    this.generation++;
  }

  // ── 리프레시 ──────────────────────────────────────────────

  private refresh(): Promise<AuthSession | null> {
    if (this.inflight) return this.inflight;
    const p = this.doRefresh().finally(() => {
      this.inflight = null;
    });
    this.inflight = p;
    return p;
  }

  private async doRefresh(): Promise<AuthSession | null> {
    const saved = await this.storage.read();
    if (!saved) return null;
    if (isAccessTokenValid(saved)) return saved;
    const refreshToken = saved.refreshToken;
    if (!refreshToken || !isRefreshTokenValid(saved, Date.now(), -CLOCK_SKEW_MS)) {
      await this.clearSession();
      return null;
    }
    if (this.retryNotBefore && Date.now() < this.retryNotBefore) {
      throw new AuthRefreshUnavailableError(new Error('backoff'));
    }
    const generation = this.generation;
    try {
      const tokens = await AuthSessionLib.refreshAsync(
        { clientId: this.clientId, refreshToken, scopes: this.rememberMe ? SCOPES : SESSION_SCOPES },
        this.discovery,
      );
      if (generation !== this.generation) {
        if (tokens.refreshToken) await this.revoke(tokens.refreshToken);
        return this.storage.read();
      }
      const nextRefresh = tokens.refreshToken ?? refreshToken;
      const session: AuthSession = {
        accessToken: tokens.accessToken,
        refreshToken: nextRefresh,
        idToken: tokens.idToken ?? saved.idToken,
        accessTokenExpiresAt: expiresAt(tokens),
        refreshTokenExpiresAt: tokens.refreshToken ? expiryFromJwt(nextRefresh) : saved.refreshTokenExpiresAt,
        username: saved.username ?? usernameFromJwt(tokens.idToken),
        email: saved.email ?? emailFromJwt(tokens.idToken),
      };
      this.retryNotBefore = null;
      await this.storage.save(session, this.rememberMe);
      this.emit(session);
      return session;
    } catch (e) {
      if (generation !== this.generation) return this.storage.read();
      if (isPermanentRefreshError(e)) {
        await this.clearSession();
        return null;
      }
      this.retryNotBefore = Date.now() + RETRY_BACKOFF_MS;
      throw new AuthRefreshUnavailableError(e);
    }
  }

  private async clearSession() {
    await this.storage.clear();
    this.retryNotBefore = null;
    this.emit(null);
  }

  private async revoke(token: string) {
    try {
      await this.postForm(this.discovery.revocationEndpoint, {
        client_id: this.clientId,
        token,
        token_type_hint: 'refresh_token',
      });
    } catch {
      // 베스트 에포트
    }
  }

  private async postForm(url: string, data: Record<string, string>) {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: Object.entries(data)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&'),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
  }

  private toSession(t: AuthSessionLib.TokenResponse): AuthSession {
    return {
      accessToken: t.accessToken,
      refreshToken: t.refreshToken ?? null,
      idToken: t.idToken ?? null,
      accessTokenExpiresAt: expiresAt(t),
      refreshTokenExpiresAt: expiryFromJwt(t.refreshToken),
      username: usernameFromJwt(t.idToken) ?? usernameFromJwt(t.accessToken),
      email: emailFromJwt(t.idToken) ?? emailFromJwt(t.accessToken),
    };
  }
}

function expiresAt(t: AuthSessionLib.TokenResponse): number | null {
  return t.expiresIn ? (t.issuedAt + t.expiresIn) * 1000 : expiryFromJwt(t.accessToken);
}

export const authRepository = new AuthRepository();
