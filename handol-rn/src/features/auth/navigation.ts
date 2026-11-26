import { useCallback } from 'react';
import { useNavigationContainerRef } from 'expo-router';

type ResetTarget = 'login' | 'home';

/** 루트 스택의 화면 이름. 홈은 탭 셸 첫 탭(home)이다 */
const ROOT_ROUTE: Record<ResetTarget, string> = { login: 'login', home: '(tabs)' };

/**
 * Flutter context.go 대응: 쌓인 화면을 모두 비우고 target 하나만 남긴다.
 * 로그아웃·탈퇴 뒤 뒤로가기로 탭 화면에 돌아가지 못한다.
 */
export function useResetTo(): (target: ResetTarget) => void {
  const navigationRef = useNavigationContainerRef();
  return useCallback(
    (target: ResetTarget) => navigationRef.reset({ index: 0, routes: [{ name: ROOT_ROUTE[target] }] }),
    [navigationRef],
  );
}
