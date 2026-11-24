import type { EmptyClass } from '@/features/empty_class/model';

/** 호실 상태 (2538:17489 범례). 전체 강의실 목록을 못 받으면 빈 호실만 나온다. */
export type RoomStatus = 'empty' | 'busy';
export const ROOM_STATUS_LABEL: Record<RoomStatus, string> = { empty: '비어있음', busy: '수업예정' };
export const ROOM_STATUSES: readonly RoomStatus[] = ['empty', 'busy'];

export interface RoomRow {
  room: string;
  status: RoomStatus;
}

export interface BuildingRows {
  building: EmptyClass;
  rooms: RoomRow[];
}

export type RoomSort = 'building' | 'count';
export const ROOM_SORT_LABEL: Record<RoomSort, string> = { building: '건물순', count: '빈 강의실 많은순' };

/** 건물의 호실과 상태. 전체 목록이 있으면 전체를, 없으면 빈 호실만 */
export function roomsWithStatus(b: EmptyClass): RoomRow[] {
  const empty = new Set(b.classList);
  const rooms = b.allRooms.length === 0 ? b.classList : b.allRooms;
  return rooms.map((room) => ({ room, status: empty.has(room) ? 'empty' : 'busy' }));
}

/** 첫 숫자를 층으로 본다 (`217호` → `2층`). 숫자가 없으면 '기타' */
export function floorOf(room: string): string {
  const m = /\d/.exec(room);
  return m ? `${m[0]}층` : '기타';
}

/** 층별로 묶고 층 이름 순(기타는 마지막)으로 정렬 */
export function groupByFloor(rooms: readonly RoomRow[]): { floor: string; rooms: RoomRow[] }[] {
  const map = new Map<string, RoomRow[]>();
  for (const r of rooms) {
    const f = floorOf(r.room);
    map.set(f, [...(map.get(f) ?? []), r]);
  }
  return [...map.entries()]
    .sort(([a], [b]) => (a === '기타' ? 1 : b === '기타' ? -1 : a < b ? -1 : a > b ? 1 : 0))
    .map(([floor, list]) => ({ floor, rooms: list }));
}

/** 검색어가 건물명에 맞으면 건물 전체를, 아니면 호실 이름에 맞는 호실만 남긴다. */
export function visibleRows(items: readonly EmptyClass[], search: string, sort: RoomSort): BuildingRows[] {
  const q = search.replace(/ /g, '');
  const rows: BuildingRows[] = [];
  for (const b of items) {
    const rooms = roomsWithStatus(b);
    if (!q || b.className.includes(q)) {
      rows.push({ building: b, rooms });
      continue;
    }
    const hit = rooms.filter((r) => `${b.className}${r.room}`.includes(q));
    if (hit.length > 0) rows.push({ building: b, rooms: hit });
  }
  if (sort === 'count') rows.sort((a, b) => b.building.emptyCount - a.building.emptyCount);
  return rows;
}
