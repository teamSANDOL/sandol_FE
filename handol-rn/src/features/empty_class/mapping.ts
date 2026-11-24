import { buildingIcon, buildingLocations, buildingOrder } from './buildingLocations';
import type { EmptyClass } from './model';

/** GET /classroom-timetable/classrooms/available/time 항목 */
export interface AvailableClassroomsDto {
  building: string;
  empty_classrooms: string[];
}

/** GET /classroom-timetable/classrooms 항목 */
export interface BuildingClassroomsDto {
  building: string;
  classrooms: string[];
}

function build(name: string, empty: string[], all: string[]): EmptyClass {
  const loc = buildingLocations[name];
  return {
    className: name,
    icon: buildingIcon(name),
    classList: empty,
    emptyCount: empty.length,
    latitude: loc?.latitude ?? null,
    longitude: loc?.longitude ?? null,
    totalCount: all.length,
    allRooms: all,
  };
}

/** 건물별 전체 강의실 (중복 제거 · 정렬) */
export function toRoomMap(rows: readonly BuildingClassroomsDto[]): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  for (const r of rows) out[r.building] = [...new Set(r.classrooms)].sort();
  return out;
}

/**
 * 조회 구간 응답 + 전체 강의실 → 건물 목록. 구간 내내 빈 강의실이 없는 건물은 응답에서 빠지므로
 * 전체 목록에 있는 건물이면 0개로 채운다. 캠퍼스 순회 순서로 정렬.
 */
export function buildEmptyClasses(
  available: readonly AvailableClassroomsDto[],
  allRooms: Readonly<Record<string, string[]>>,
): EmptyClass[] {
  const list = available.map((a) => build(a.building, [...a.empty_classrooms].sort(), allRooms[a.building] ?? []));
  const present = new Set(list.map((e) => e.className));
  for (const [name, rooms] of Object.entries(allRooms)) {
    if (!present.has(name)) list.push(build(name, [], rooms));
  }
  return list.sort((a, b) => buildingOrder(a.className) - buildingOrder(b.className));
}
