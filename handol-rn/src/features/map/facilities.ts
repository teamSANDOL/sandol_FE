import type { IconName } from '@/design-system';
import type { MaterialIconName } from '@/features/empty_class/components/MaterialIcon';

/** 교내 시설 분류. 시설 바로가기 · 필터 · 건물 시트가 같은 이름과 아이콘을 쓴다. */
export interface Facility {
  label: string;
  /** 시안 아이콘(Figma 2915:1268, SVG). 시안에서 내보내지 않은 분류는 material 로 대신한다. */
  icon?: IconName;
  material: MaterialIconName;
}

export const facilities = {
  all: { label: '전체', material: 'gridView' },
  emptyClass: { label: '빈 강의실', icon: 'mapEmptyClass', material: 'meetingRoom' },
  restaurant: { label: '식당', icon: 'mapRestaurant', material: 'restaurant' },
  cafe: { label: '카페', icon: 'mapCafe', material: 'gridView' },
  printer: { label: '프린트', icon: 'mapPrinter', material: 'gridView' },
  studyRoom: { label: '스터디룸', icon: 'mapStudyRoom', material: 'gridView' },
  library: { label: '도서관', icon: 'mapLibrary', material: 'gridView' },
  store: { label: '편의점', icon: 'mapStore', material: 'gridView' },
  vending: { label: '자판기', icon: 'mapVending', material: 'gridView' },
  lounge: { label: '휴게공간', material: 'weekend' },
  etc: { label: '기타', material: 'moreHoriz' },
} as const satisfies Record<string, Facility>;

export type FacilityKey = keyof typeof facilities;
