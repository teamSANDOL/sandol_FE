import { useCallback } from 'react';
import { useNavigationContainerRef } from 'expo-router';

type ResetTarget = 'login' | 'home';

/** 루트 스택의 화면 이름. 홈은 탭 셸 첫 탭(home)이다 */
const ROOT_ROUTE: Record<ResetTarget, string> = { login: 'login', home: '(tabs)' };

type NavState = { index: number; routeNames?: string[]; routes: { key: string; name: string; state?: unknown }[] };

/**
 * name 화면 하나만 남긴 상태. expo-router 는 루트 컨테이너 아래(__root)에 앱 스택을 두므로
 * name 을 가진 스택을 찾아 내려가고, 그 위 단계들은 그대로 감싼다.
 * 지금 내비게이션은 부분 상태 reset 을 무시하므로 key·routeNames 등 기존 필드를 그대로 둔다.
 */
export function withOnlyRoute(state: NavState, name: string): NavState | undefined {
  if (state.routeNames?.includes(name)) return { ...state, index: 0, routes: [{ name, key: `${name}-${Date.now()}` }] };
  const focused = state.routes[state.index];
  const child = focused?.state as NavState | undefined;
  const next = child && withOnlyRoute(child, name);
  if (!next) return undefined;
  return { ...state, routes: state.routes.map((r, i) => (i === state.index ? { ...r, state: next } : r)) };
}

/**
 * Flutter context.go 대응: 쌓인 화면을 모두 비우고 target 하나만 남긴다.
 * 로그아웃·탈퇴 뒤 뒤로가기로 탭 화면에 돌아가지 못한다.
 */
export function useResetTo(): (target: ResetTarget) => void {
  const navigationRef = useNavigationContainerRef();
  return useCallback(
    (target: ResetTarget) => {
      const next = withOnlyRoute(navigationRef.getRootState() as unknown as NavState, ROOT_ROUTE[target]);
      if (next) navigationRef.reset(next as never);
    },
    [navigationRef],
  );
}
