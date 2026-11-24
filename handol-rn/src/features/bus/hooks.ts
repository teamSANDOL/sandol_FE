import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useUserLocation } from '@/core/location/userLocation';
import { isoDate } from '@/core/utils/dateFormatter';
import { buildBoard, type ShuttleBoard } from './board';
import { reversedDirection, type ShuttleDirection, type ShuttleStops } from './model';
import { nearestShuttleDirection } from './nearestOrigin';
import { fetchRemoteSchedule, readScheduleCache, usableOn } from './remoteSource';
import type { RemoteSchedule } from './remoteSchedule';
import { BUILTIN_STOPS } from './scheduleData';
import { chooseDirection, useChosenDirection, useShuttleClockMinute } from './store';

const SCHEDULE_STALE_MS = 5 * 60_000;

/** 기준 시각 + 서버 시간표(없으면 null → 내장) + 정류장. 대체 순서: 서버 → 기기 캐시 → 내장 */
export function useShuttleSchedule() {
  const minute = useShuttleClockMinute();
  const now = useMemo(() => new Date(minute), [minute]); // KST 벽시계 (getUTC*)
  const todayIso = isoDate(now);

  const cacheQuery = useQuery({ queryKey: ['bus', 'timetable-cache'], queryFn: readScheduleCache, staleTime: Infinity });
  const cached = cacheQuery.data ?? null;
  const remoteQuery = useQuery({
    queryKey: ['bus', 'timetable', todayIso],
    queryFn: () => fetchRemoteSchedule(todayIso, cached),
    enabled: cacheQuery.isFetched,
    staleTime: SCHEDULE_STALE_MS,
    retry: false,
  });

  const schedule: RemoteSchedule | null =
    remoteQuery.data ?? (cached && usableOn(cached, todayIso, now) ? cached : null);
  const stops: ShuttleStops = useMemo(() => ({ ...BUILTIN_STOPS, ...schedule?.stops }), [schedule]);
  return { now, schedule, stops };
}

/**
 * 셔틀 방향 선택(6방향). 홈 카드와 탭이 공유한다. 사용자가 직접 고르기 전에는 가까운 정류장 출발이 기본이고,
 * 고른 뒤에는 위치가 갱신돼도 되돌리지 않는다. 위치는 구독만 하므로 이 기능이 권한 창을 새로 띄우지 않는다.
 */
export function useShuttleDirection(): [ShuttleDirection, (d: ShuttleDirection) => void] {
  const chosen = useChosenDirection();
  const { data: position } = useUserLocation();
  const { stops } = useShuttleSchedule();
  const nearest = position ? nearestShuttleDirection(position, stops) : null;
  return [chosen ?? nearest ?? 'schoolToJeongwang', chooseDirection];
}

/** 한 방향의 다음 셔틀 · 이후 출발 · 환승 · 시간표 + 정류장 · 기준 시각 */
export function useShuttleBoard(direction: ShuttleDirection): ShuttleBoard & {
  now: Date;
  nowMinutes: number;
  stops: ShuttleStops;
  needsReview: boolean;
  reversed: ShuttleDirection;
} {
  const { now, schedule, stops } = useShuttleSchedule();
  const board = useMemo(() => buildBoard(schedule, direction, now), [schedule, direction, now]);
  return {
    ...board,
    now,
    nowMinutes: now.getUTCHours() * 60 + now.getUTCMinutes(),
    stops,
    needsReview: schedule?.needsReview ?? false,
    reversed: reversedDirection(direction),
  };
}
