import { useSyncExternalStore } from 'react';

/**
 * 홈 → 맵 탭으로 넘어갈 때 "이 건물의 빈 강의실 현황을 띄워라" 요청 (empty_class_focus_provider).
 * 맵 화면이 소비하면 consumeEmptyClassFocus() 로 비운다.
 */
let pending: string | null = null;
const listeners = new Set<() => void>();

export function requestEmptyClassFocus(buildingName: string): void {
  pending = buildingName;
  listeners.forEach((l) => l());
}

export function consumeEmptyClassFocus(): string | null {
  const v = pending;
  pending = null;
  listeners.forEach((l) => l());
  return v;
}

export function usePendingEmptyClassFocus(): string | null {
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => pending,
  );
}
