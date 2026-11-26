import type { AuthStatus } from '@/core/auth/AuthProvider';

export type SplashTarget = '/home' | '/login';

/**
 * 스플래시가 넘어갈 곳. 세션 복원 중이면 null(대기).
 * 로그인 상태이거나 둘러보기 기록이 7일 안이면 홈, 아니면 로그인.
 */
export function splashTarget(status: AuthStatus, isGuestActive: boolean): SplashTarget | null {
  if (status === 'restoring') return null;
  return status === 'signedIn' || isGuestActive ? '/home' : '/login';
}
