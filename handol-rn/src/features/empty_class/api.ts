import { api } from '@/core/api/client';
import { buildEmptyClasses, toRoomMap, type AvailableClassroomsDto, type BuildingClassroomsDto } from './mapping';
import { dayName, formatMinutes, type ClassroomQuery } from './query';
import type { EmptyClass } from './model';

/** 강의실 시간표 서비스 (teamSANDOL/sandol_classroom_timetable). 인증 불필요 */
const BASE = '/classroom-timetable';

/** 건물별 전체 강의실은 학기 단위로만 바뀌므로 앱 수명 동안 캐시한다. 실패는 캐시하지 않는다. */
let roomsCache: Record<string, string[]> | null = null;

async function loadRooms(): Promise<Record<string, string[]>> {
  if (roomsCache) return roomsCache;
  try {
    const rows = await api.get<BuildingClassroomsDto[]>(`${BASE}/classrooms`, { auth: false });
    roomsCache = toRoomMap(rows);
    return roomsCache;
  } catch {
    // 전체 목록 실패는 치명적이지 않다 — 수업예정 호실만 못 그린다.
    return {};
  }
}

export async function fetchEmptyClasses(query: ClassroomQuery): Promise<EmptyClass[]> {
  const [available, rooms] = await Promise.all([
    api.get<AvailableClassroomsDto[]>(`${BASE}/classrooms/available/time`, {
      auth: false,
      query: { day: dayName(query), start_time: formatMinutes(query.startMinutes), end_time: formatMinutes(query.endMinutes) },
    }),
    loadRooms(),
  ]);
  return buildEmptyClasses(available, rooms);
}
