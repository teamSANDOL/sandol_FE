import { useSyncExternalStore } from 'react';
import {
  clockOf,
  defaultFor,
  setDay as setDayOf,
  setRange as setRangeOf,
  setRangeByTick as setRangeByTickOf,
  syncToNow as syncToNowOf,
  type ClassroomQuery,
  type Clock,
} from './query';

/**
 * 홈 카드와 맵 탭이 함께 보는 조회 구간 (ClassroomQueryController, keepAlive).
 * 앱이 살아 있는 동안 사용자가 고른 구간과 축 기준 시각을 유지한다.
 */
let state: ClassroomQuery | null = null;
const listeners = new Set<() => void>();

function current(): ClassroomQuery {
  state ??= defaultFor(clockOf());
  return state;
}

function update(fn: (q: ClassroomQuery, clock: Clock) => ClassroomQuery): void {
  const prev = current();
  const next = fn(prev, clockOf());
  if (next === prev) return;
  state = next;
  listeners.forEach((l) => l());
}

export const classroomQueryActions = {
  setRangeByTick: (s: number, e: number) => update((q) => setRangeByTickOf(q, s, e)),
  setRange: (s: number, e: number) => update((q) => setRangeOf(q, s, e)),
  setDay: (daysAhead: number) => update((q, c) => setDayOf(q, c, daysAhead)),
  resetToNow: () => update((_, c) => defaultFor(c)),
  syncToNow: () => update((q, c) => syncToNowOf(q, c)),
};

export function useClassroomQuery(): ClassroomQuery {
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    current,
  );
}
