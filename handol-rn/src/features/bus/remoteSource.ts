import AsyncStorage from '@react-native-async-storage/async-storage';
import { api, ApiError } from '@/core/api/client';
import { dayTypeOf } from './scheduleData';
import { parseRemoteSchedule, type RemoteSchedule } from './remoteSchedule';

export const CACHE_KEY = 'bus.shuttle_timetable';

/** 마지막 성공 응답(기기 캐시). 없거나 깨졌으면 null */
export async function readScheduleCache(): Promise<RemoteSchedule | null> {
  try {
    const raw = await AsyncStorage.getItem(CACHE_KEY);
    return raw ? parseRemoteSchedule(JSON.parse(raw)) : null;
  } catch {
    return null;
  }
}

/**
 * 서버를 못 받을 때 cached 를 today 에 써도 되는지. 같은 날이면 그대로,
 * 다른 날이면 앱 공휴일 목록으로 본 오늘 요일 구분이 같을 때만 쓴다. (today = KST 벽시계 Date)
 * ponytail: 오프라인이 학기 경계를 넘기면 지난 학기 캐시가 남는다. valid_from/valid_to 는 다시 보지 않는다.
 */
export function usableOn(cached: RemoteSchedule, todayIso: string, today: Date): boolean {
  return cached.date === todayIso || cached.dayType === dayTypeOf(today);
}

/**
 * 오늘(KST) 시간표를 서버에서 받는다. 같은 날 캐시가 있으면 version 으로 If-None-Match 를 붙이고 304 면 캐시를 쓴다
 * (version 은 날짜와 무관해 다른 날 캐시에는 붙이지 않는다). 실패 · 형식 불일치면 null → 호출부가 캐시 · 내장으로 대체한다.
 */
export async function fetchRemoteSchedule(todayIso: string, cached: RemoteSchedule | null): Promise<RemoteSchedule | null> {
  const sameDay = cached?.date === todayIso;
  try {
    const body = await api.get<unknown>('/static-info/bus/timetable', {
      query: { date: todayIso },
      headers: sameDay && cached ? { 'If-None-Match': `"${cached.version}"` } : undefined,
    });
    const remote = parseRemoteSchedule(body);
    if (!remote) return null;
    await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(body)).catch(() => undefined);
    return remote;
  } catch (e) {
    return e instanceof ApiError && e.status === 304 ? cached : null;
  }
}
