import { useQuery } from '@tanstack/react-query';
import { api, resolveUrl } from '@/core/api/client';
import { env } from '@/core/env';
import type { MaterialIconName } from '@/features/empty_class/components/MaterialIcon';

/** TUK 월드(총학생회 제휴 업체) 한 곳. GET /static-info/tuk-world/restaurants 항목 */
export interface TukPlace {
  id: number;
  name: string;
  /** 서버는 자유 문자열이지만 현재 `식당`·`술집`·`여가`를 쓴다. */
  category: string | null;
  address: string | null;
  latitude: number;
  longitude: number;
  /** 제휴 혜택. 형식 자유, 줄바꿈 포함 */
  discountInfo: string | null;
  imageUrls: string[];
}

interface TukPlaceDto {
  id: number;
  name: string;
  category?: string | null;
  address?: string | null;
  latitude: number;
  longitude: number;
  discount_info?: string | null;
  images?: { url: string }[] | null;
}

/** 서버가 경로만 주면 base 기준 절대 주소로 푼다 */
export function resolveRemoteUrl(url: string, base: string): string {
  return resolveUrl(url, base);
}

export function toTukPlace(dto: TukPlaceDto, base: string): TukPlace {
  return {
    id: dto.id,
    name: dto.name,
    category: dto.category ?? null,
    address: dto.address ?? null,
    latitude: dto.latitude,
    longitude: dto.longitude,
    discountInfo: dto.discount_info ?? null,
    imageUrls: (dto.images ?? []).map((i) => resolveRemoteUrl(i.url, base)),
  };
}

/** TUK 월드 분류. 'all' 은 필터 없음. 서버 분류 문자열과 label 이 같다. */
export type TukCategory = 'all' | 'leisure' | 'food' | 'bar';

export const TUK_CATEGORIES: readonly TukCategory[] = ['all', 'leisure', 'food', 'bar'];

export const tukCategoryInfo: Readonly<Record<TukCategory, { label: string; icon: MaterialIconName }>> = {
  all: { label: '전체', icon: 'gridView' },
  leisure: { label: '여가', icon: 'ticket' },
  food: { label: '식당', icon: 'restaurant' },
  bar: { label: '술집', icon: 'bar' },
};

export function tukMatches(category: TukCategory, p: TukPlace): boolean {
  return category === 'all' || p.category === tukCategoryInfo[category].label;
}

/** 마커·썸네일 아이콘용. 모르는 분류는 식당으로 그린다. */
export function tukIconOf(p: TukPlace): MaterialIconName {
  const found = TUK_CATEGORIES.find((c) => c !== 'all' && tukCategoryInfo[c].label === p.category);
  return tukCategoryInfo[found ?? 'food'].icon;
}

export async function fetchTukPlaces(): Promise<TukPlace[]> {
  const rows = await api.get<TukPlaceDto[]>('/static-info/tuk-world/restaurants', { auth: false });
  return rows.map((r) => toTukPlace(r, env.apiBaseUrl));
}

/** 제휴 업체 전체. 분류 필터는 화면에서 한다(수십 곳 규모). */
export function useTukPlaces(enabled: boolean) {
  return useQuery({ queryKey: ['map', 'tukWorld'], queryFn: fetchTukPlaces, enabled });
}
