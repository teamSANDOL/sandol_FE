import { useEffect, useReducer, useSyncExternalStore } from 'react';
import { AppState } from 'react-native';
import { koreaNow } from '@/core/utils/koreaTime';
import type { ShuttleDirection } from './model';

/**
 * 셔틀 전역 상태 (Flutter ShuttleClock · ShuttleDirectionSelection provider 대응).
 * 홈 카드와 셔틀 탭이 같은 시각 · 방향을 본다.
 */

const MINUTE_MS = 60_000;
const BOUNDARY_SLACK_MS = 50;

// ── 시계: KST 벽시계를 분 단위로 자른 epoch ms ───────────────────────────────

const truncatedKstMinute = (): number => {
  const t = koreaNow().getTime();
  return t - (t % MINUTE_MS);
};

let minute = truncatedKstMinute();
const clockListeners = new Set<() => void>();
let timer: ReturnType<typeof setTimeout> | null = null;
let appActive = AppState.currentState === 'active';
let appSub: { remove: () => void } | null = null;

function advance(): void {
  const m = truncatedKstMinute();
  if (m === minute) return; // 같은 분이면 재계산 없음
  minute = m;
  clockListeners.forEach((l) => l());
}

function disarm(): void {
  if (timer) clearTimeout(timer);
  timer = null;
}

/** 다음 분 경계 직후 한 번 깨어난다 (폴링보다 깨어나는 횟수가 적고 표시가 어긋나지 않는다) */
function arm(): void {
  if (!appActive || clockListeners.size === 0 || timer) return;
  const untilNextMinute = MINUTE_MS - (koreaNow().getTime() % MINUTE_MS) + BOUNDARY_SLACK_MS;
  timer = setTimeout(() => {
    timer = null;
    advance();
    arm();
  }, untilNextMinute);
}

function onAppState(state: string): void {
  appActive = state === 'active';
  if (appActive) {
    advance();
    arm();
  } else {
    disarm();
  }
}

function subscribeClock(listener: () => void): () => void {
  clockListeners.add(listener);
  if (clockListeners.size === 1) {
    appActive = AppState.currentState === 'active';
    appSub = AppState.addEventListener('change', onAppState);
    advance(); // 구독자 없는 동안 흐른 시간을 즉시 맞춘다
    arm();
  }
  return () => {
    clockListeners.delete(listener);
    if (clockListeners.size === 0) {
      disarm();
      appSub?.remove();
      appSub = null;
    }
  };
}

/** 셔틀 계산 기준 시각 (KST 벽시계 분 단위 epoch ms). 분이 바뀔 때마다 갱신된다 */
export const useShuttleClockMinute = (): number => useSyncExternalStore(subscribeClock, () => minute);

/** 당겨서 새로고침 · 카드 버튼 · 백그라운드 복귀처럼 즉시 맞출 때 */
export const refreshShuttleClock = advance;

// ── 앱 활성 여부 + 1초 tick (홈 카운트다운) ───────────────────────────────────

function subscribeAppState(listener: () => void): () => void {
  const sub = AppState.addEventListener('change', listener);
  return () => sub.remove();
}

export const useAppActive = (): boolean => useSyncExternalStore(subscribeAppState, () => AppState.currentState === 'active');

/** enabled 이고 앱이 보일 때만 매초 다시 그린다. 반환값은 현재 KST 초 */
export function useSecondTick(enabled: boolean): number {
  const active = useAppActive();
  const [, bump] = useReducer((n: number) => n + 1, 0);
  useEffect(() => {
    if (!enabled || !active) return;
    const id = setInterval(bump, 1000);
    return () => clearInterval(id);
  }, [enabled, active]);
  return koreaNow().getUTCSeconds();
}

// ── 방향: 사용자가 직접 고른 값. 없으면 위치 기반 기본값 ─────────────────────────

let chosenDirection: ShuttleDirection | null = null;
const directionListeners = new Set<() => void>();

export function chooseDirection(d: ShuttleDirection): void {
  chosenDirection = d;
  directionListeners.forEach((l) => l());
}

export function useChosenDirection(): ShuttleDirection | null {
  return useSyncExternalStore(
    (l) => {
      directionListeners.add(l);
      return () => directionListeners.delete(l);
    },
    () => chosenDirection,
  );
}

/** 테스트용 */
export function resetShuttleStore(): void {
  chosenDirection = null;
}
