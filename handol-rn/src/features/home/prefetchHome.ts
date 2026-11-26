import type { QueryClient } from '@tanstack/react-query';
import { fetchEmptyClasses } from '@/features/empty_class/api';
import { clockOf, dayName, defaultFor, formatMinutes } from '@/features/empty_class/query';
import { fetchOrganizationTree } from '@/features/organization/api';
import { fetchMeals, fetchRestaurants } from '@/features/school_meal/api';
import { todayIso } from '@/features/school_meal/model';

/** 네트워크가 느려도 스플래시에 갇히지 않게 하는 선로딩 대기 상한 (Flutter _preloadLimit) */
const PRELOAD_LIMIT_MS = 5_000;

/**
 * 홈 첫 화면이 쓰는 네트워크 데이터(학식 · 식단 · 빈 강의실 · 조직도)를 받아 둔다. 최대 5초.
 * 위치는 권한 창이 스플래시 위에 뜨지 않게 홈에서 받고, 셔틀은 내장 시간표라 뺀다.
 * 키는 각 기능의 hooks.ts 와 같아야 홈이 이 캐시를 그대로 쓴다.
 * 실패한 섹션은 홈에서 각자 오류·재시도를 보여 주므로 여기선 기다리기만 한다(prefetchQuery 는 던지지 않는다).
 */
export function prefetchHome(client: QueryClient): Promise<unknown> {
  const day = todayIso();
  // 스플래시 시점엔 조회 구간을 아직 아무도 바꾸지 않았으므로 기본 구간(queryStore 초기값)과 같다.
  const q = defaultFor(clockOf());
  const all = Promise.all([
    client.prefetchQuery({ queryKey: ['school_meal', 'restaurants'], queryFn: fetchRestaurants }),
    client.prefetchQuery({ queryKey: ['school_meal', 'meals', day], queryFn: () => fetchMeals(day) }),
    client.prefetchQuery({
      queryKey: ['emptyClasses', dayName(q), formatMinutes(q.startMinutes), formatMinutes(q.endMinutes)],
      queryFn: () => fetchEmptyClasses(q),
    }),
    client.prefetchQuery({ queryKey: ['organization', 'tree'], queryFn: fetchOrganizationTree, staleTime: 5 * 60_000 }),
  ]);
  return Promise.race([all, new Promise((resolve) => setTimeout(resolve, PRELOAD_LIMIT_MS))]);
}
