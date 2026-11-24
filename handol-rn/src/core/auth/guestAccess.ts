import * as SecureStore from 'expo-secure-store';

const KEY = 'guest_browsing_started_at';
/** 둘러보기 기록이 유효한 기간 */
export const GUEST_VALID_FOR_MS = 7 * 24 * 60 * 60 * 1000;

/** "로그인 없이 둘러보기" 시각. 7일 안이면 앱 시작 때 로그인 화면 없이 홈으로 간다 */
export const guestAccess = {
  async start(now = Date.now()): Promise<void> {
    try {
      await SecureStore.setItemAsync(KEY, new Date(now).toISOString());
    } catch {
      // 쓰기 실패는 로그인 화면으로 한 번 더 돌아올 뿐이라 막지 않는다.
    }
  },
  async clear(): Promise<void> {
    try {
      await SecureStore.deleteItemAsync(KEY);
    } catch {
      // 무시
    }
  },
  /** 기록이 있고 7일이 지나지 않았는지. 손상된 값 · 미래 시각은 만료로 본다 */
  async isActive(now = Date.now()): Promise<boolean> {
    try {
      const raw = await SecureStore.getItemAsync(KEY);
      const started = raw ? Date.parse(raw) : NaN;
      if (Number.isNaN(started)) return false;
      const elapsed = now - started;
      return elapsed >= 0 && elapsed < GUEST_VALID_FOR_MS;
    } catch {
      return false;
    }
  },
};
