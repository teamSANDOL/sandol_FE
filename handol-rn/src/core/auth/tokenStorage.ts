import * as SecureStore from 'expo-secure-store';
import type { AuthSession } from './session';

const KEY = 'auth_session_v1';
/** 명시적 로그아웃 · 탈퇴 뒤 다음 로그인에 재인증을 요구하는 표시. clear 로 지우지 않는다 */
const FORCE_LOGIN_KEY = 'auth_force_login';

/**
 * 토큰을 기기 보안 저장소(Keystore/Keychain)에 보관하고, 매 요청마다 읽지 않도록 메모리에 캐시한다.
 * 저장소 예외는 위로 올리지 않는다(스플래시가 멈춘다). 이번 읽기만 비로그인으로 답하고 다음에 다시 시도한다.
 */
export class TokenStorage {
  private cached: AuthSession | null = null;
  private loaded = false;

  async read(): Promise<AuthSession | null> {
    if (this.loaded) return this.cached;
    try {
      const raw = await SecureStore.getItemAsync(KEY);
      this.cached = raw ? (JSON.parse(raw) as AuthSession) : null;
      this.loaded = true;
      return this.cached;
    } catch {
      return null;
    }
  }

  /** persist=false("로그인 상태 유지" 해제)면 디스크 세션을 지우고 메모리에만 둔다 */
  async save(session: AuthSession, persist = true): Promise<void> {
    if (persist) {
      await SecureStore.setItemAsync(KEY, JSON.stringify(session));
    } else {
      await SecureStore.deleteItemAsync(KEY);
    }
    this.cached = session;
    this.loaded = true;
  }

  /** 메모리 세션을 먼저 비운다. 디스크 삭제 실패는 다음 save 가 덮어쓰므로 로그아웃 · 탈퇴를 막지 않는다. */
  async clear(): Promise<void> {
    this.cached = null;
    this.loaded = true;
    try {
      await SecureStore.deleteItemAsync(KEY);
    } catch {
      // 무시
    }
  }

  /** 읽기 실패 시 안전한 쪽(true) */
  async readForceLogin(): Promise<boolean> {
    try {
      return (await SecureStore.getItemAsync(FORCE_LOGIN_KEY)) === 'true';
    } catch {
      return true;
    }
  }

  async writeForceLogin(value: boolean): Promise<void> {
    try {
      if (value) await SecureStore.setItemAsync(FORCE_LOGIN_KEY, 'true');
      else await SecureStore.deleteItemAsync(FORCE_LOGIN_KEY);
    } catch {
      // 베스트 에포트: 로그인 · 로그아웃 자체는 막지 않는다.
    }
  }
}
