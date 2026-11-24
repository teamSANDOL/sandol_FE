/** 건물별 빈 강의실 (EmptyClass). 기존 UI 호환용 문자열 필드는 쓰지 않고 숫자로 둔다. */
export interface EmptyClass {
  /** 백엔드 건물명 (예: `E동`, `산융`, `TIP`) */
  className: string;
  /** 건물 아이콘 (require 모듈) */
  icon: number;
  /** 조회 구간 내내 비어 있는 강의실 (예: `217호`) */
  classList: string[];
  emptyCount: number;
  /** 좌표 테이블에 없는 건물은 null → 지도 마커·거리 계산 생략 */
  latitude: number | null;
  longitude: number | null;
  /** 건물 전체 강의실 수. 모르면 0 */
  totalCount: number;
  /** 건물 전체 강의실(정렬됨). 못 불러왔으면 빈 배열 */
  allRooms: string[];
}

export function hasLocation(b: EmptyClass): b is EmptyClass & { latitude: number; longitude: number } {
  return b.latitude !== null && b.longitude !== null;
}
