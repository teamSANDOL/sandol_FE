import { distanceMeters, type UserPosition } from '@/core/location/userLocation';
import { buildingOrder } from './buildingLocations';
import { hasLocation, type EmptyClass } from './model';

/** 홈 카드 건물 정렬 방식 */
export type BuildingSort = 'distance' | 'count' | 'custom';

export const BUILDING_SORTS: readonly BuildingSort[] = ['distance', 'count', 'custom'];

export const BUILDING_SORT_LABELS: Readonly<Record<BuildingSort, string>> = {
  distance: '내 위치 정렬',
  count: '빈 강의실 많은 순',
  custom: '내 순서 정렬',
};

/** 정렬 설정. 기기 로컬에 저장되며 서버와 무관하다. */
export interface BuildingSortSettings {
  mode: BuildingSort;
  /** custom 에서 쓰는 건물명 순서. 없는 건물은 뒤로 간다. */
  customOrder: readonly string[];
}

export const defaultSortSettings: BuildingSortSettings = { mode: 'distance', customOrder: [] };

/** 홈 카드용: 건물별 빈 강의실 + 내 위치로부터의 거리 */
export interface NearbyEmptyClass {
  building: EmptyClass;
  /** 내 위치를 모르거나 건물 좌표가 없으면 null */
  distanceMeters: number | null;
}

const WALK_METERS_PER_MIN = 70;

/** 캠퍼스 보행 속도(약 70m/분) 기준 도보 시간. 최소 1분 */
export function walkMinutes(item: NearbyEmptyClass): number | null {
  const d = item.distanceMeters;
  if (d === null) return null;
  return Math.min(99, Math.max(1, Math.ceil(d / WALK_METERS_PER_MIN)));
}

export function rankOf(settings: BuildingSortSettings, name: string): number {
  const i = settings.customOrder.indexOf(name);
  return i < 0 ? settings.customOrder.length : i;
}

/** 저장된 순서에 all 의 건물을 합친 목록. 저장된 것이 앞, 새 건물은 뒤 */
export function mergedOrder(settings: BuildingSortSettings, all: readonly string[]): string[] {
  const saved = settings.customOrder.filter((n) => all.includes(n));
  return [...saved, ...all.filter((n) => !saved.includes(n))];
}

/** Flutter ReorderableListView 의 onReorder 와 같은 의미: to 는 제거 전 기준 삽입 위치 */
export function moveItem<T>(list: readonly T[], from: number, to: number): T[] {
  const next = [...list];
  const [moved] = next.splice(from, 1);
  next.splice(to > from ? to - 1 : to, 0, moved);
  return next;
}

const byCount = (a: NearbyEmptyClass, b: NearbyEmptyClass): number =>
  b.building.emptyCount - a.building.emptyCount || buildingOrder(a.building.className) - buildingOrder(b.building.className);

/**
 * 내 위치 정렬은 거리순(위치를 모르면 빈 강의실 많은 순), 내 순서 정렬은 저장된 순서.
 * 좌표가 없는 건물은 거리순에서 항상 뒤로 간다.
 */
export function sortNearby(
  classes: readonly EmptyClass[],
  position: UserPosition | null,
  settings: BuildingSortSettings,
): NearbyEmptyClass[] {
  const items: NearbyEmptyClass[] = classes.map((c) => ({
    building: c,
    distanceMeters: position && hasLocation(c) ? distanceMeters(position, { latitude: c.latitude, longitude: c.longitude }) : null,
  }));
  switch (settings.mode) {
    case 'custom':
      return items.sort(
        (a, b) => rankOf(settings, a.building.className) - rankOf(settings, b.building.className) || byCount(a, b),
      );
    case 'count':
      return items.sort(byCount);
    case 'distance':
      return items.sort((a, b) => {
        const da = a.distanceMeters;
        const db = b.distanceMeters;
        if (da !== null && db !== null) return da - db;
        if (da !== null) return -1;
        if (db !== null) return 1;
        return byCount(a, b);
      });
  }
}
