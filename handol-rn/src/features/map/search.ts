import type { EmptyClass } from '@/features/empty_class/model';
import type { TukPlace } from './tukWorld';

export type SearchResult =
  | { kind: 'building'; title: string; sub: string; building: EmptyClass }
  | { kind: 'place'; title: string; sub: string; place: TukPlace };

/** 검색어가 이름에 들어 있는 건물 · TUK 월드 업체 (건물 먼저) */
export function searchPlaces(query: string, buildings: readonly EmptyClass[], places: readonly TukPlace[]): SearchResult[] {
  const q = query.trim();
  if (!q) return [];
  const out: SearchResult[] = [];
  for (const b of buildings) {
    if (b.className.includes(q)) out.push({ kind: 'building', title: b.className, sub: `빈 강의실 ${b.emptyCount}개`, building: b });
  }
  for (const p of places) {
    if (p.name.includes(q)) out.push({ kind: 'place', title: p.name, sub: `TUK 월드 · ${p.category ?? '제휴'}`, place: p });
  }
  return out;
}
