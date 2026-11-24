import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { AppState } from 'react-native';
import { setAccessTokenGetter } from '../api/client';
import { AuthCancelledError, authRepository, type LoginOptions } from './authRepository';
import { guestAccess } from './guestAccess';
import type { AuthSession } from './session';

export type AuthStatus = 'restoring' | 'signedIn' | 'signedOut';

type AuthContextValue = {
  status: AuthStatus;
  session: AuthSession | null;
  /** 로그인 진행 중(브라우저 열림) */
  isLoggingIn: boolean;
  /** 마지막 로그인 실패 (취소는 제외) */
  error: Error | null;
  /** 성공 true, 취소 · 실패 false */
  login: (opts?: LoginOptions) => Promise<boolean>;
  logout: () => Promise<void>;
  /** 서버 삭제 실패 시 예외가 그대로 올라온다 */
  deleteAccount: () => Promise<void>;
  /** "로그인 없이 둘러보기" */
  continueAsGuest: () => Promise<void>;
  refreshIfNeeded: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

setAccessTokenGetter(() => authRepository.getValidAccessToken());

/** 세션 상태 (Flutter AuthNotifier). 앱 복귀 시 미리 토큰을 갱신한다. */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<AuthSession | null>(null);
  const [status, setStatus] = useState<AuthStatus>('restoring');
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const loggingInRef = useRef(false);

  const apply = useCallback((s: AuthSession | null) => {
    setSession(s);
    setStatus(s ? 'signedIn' : 'signedOut');
  }, []);

  useEffect(() => {
    authRepository
      .restoreSession()
      .then(apply)
      .catch(() => apply(null));
    // 백그라운드 리프레시가 세션을 갱신/폐기하면 화면도 따라간다. 로그인 중에는 무시.
    const unsub = authRepository.subscribe((s) => {
      if (!loggingInRef.current) apply(s);
    });
    return () => {
      unsub();
    };
  }, [apply]);

  const refreshIfNeeded = useCallback(async () => {
    if (loggingInRef.current) return;
    try {
      const s = await authRepository.restoreSession();
      if (!loggingInRef.current) apply(s);
    } catch {
      // 다음 복귀에 다시 시도
    }
  }, [apply]);

  useEffect(() => {
    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') void refreshIfNeeded();
    });
    return () => sub.remove();
  }, [refreshIfNeeded]);

  const login = useCallback(
    async (opts?: LoginOptions) => {
      loggingInRef.current = true;
      setIsLoggingIn(true);
      setError(null);
      try {
        const s = await authRepository.login(opts);
        apply(s);
        await guestAccess.clear();
        return true;
      } catch (e) {
        if (!(e instanceof AuthCancelledError)) setError(e instanceof Error ? e : new Error(String(e)));
        return false;
      } finally {
        loggingInRef.current = false;
        setIsLoggingIn(false);
      }
    },
    [apply],
  );

  const logout = useCallback(async () => {
    await authRepository.logout();
    await guestAccess.clear();
    apply(null);
  }, [apply]);

  const deleteAccount = useCallback(async () => {
    await authRepository.deleteAccount();
    apply(null);
  }, [apply]);

  const continueAsGuest = useCallback(() => guestAccess.start(), []);

  const value = useMemo<AuthContextValue>(
    () => ({ status, session, isLoggingIn, error, login, logout, deleteAccount, continueAsGuest, refreshIfNeeded }),
    [status, session, isLoggingIn, error, login, logout, deleteAccount, continueAsGuest, refreshIfNeeded],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth 는 AuthProvider 안에서만 쓸 수 있습니다');
  return ctx;
}
