/**
 * 백엔드 건물명 → 캠퍼스 좌표·아이콘. 좌표는 OpenStreetMap 건물 폴리곤 중심(2026-09 조회).
 * 표에 없는 건물은 좌표 없이 목록에만 나온다. 표의 순서 = 캠퍼스 순회 순서.
 */
export interface BuildingLocation {
  latitude: number;
  longitude: number;
  icon: number;
}

const defaultIcon: number = require('../../../assets/img/emptyclass_filled.png');

export const buildingLocations: Readonly<Record<string, BuildingLocation>> = {
  A동: { latitude: 37.340429, longitude: 126.73289, icon: require('../../../assets/img/tino6.png') },
  B동: { latitude: 37.340353, longitude: 126.733302, icon: require('../../../assets/img/tukorea_Materials.png') },
  C동: { latitude: 37.340009, longitude: 126.733987, icon: require('../../../assets/img/tukorea_Energy.png') },
  D동: { latitude: 37.339689, longitude: 126.734144, icon: require('../../../assets/img/tukorea_Electronic.png') },
  E동: { latitude: 37.339713, longitude: 126.735044, icon: require('../../../assets/img/tukorea_computer.png') },
  G동: { latitude: 37.340264, longitude: 126.734741, icon: require('../../../assets/img/tukorea_Mechanical.png') },
  P동: { latitude: 37.339414, longitude: 126.735535, icon: defaultIcon },
  // 제2기숙사(TIP)
  TIP: { latitude: 37.341316, longitude: 126.732924, icon: defaultIcon },
  // 산학융합본부
  산융: { latitude: 37.338704, longitude: 126.73455, icon: defaultIcon },
  // 종합교육관 (중앙도서관 포함). 백엔드 별칭: 종합·종관·중도·도서관
  중앙: { latitude: 37.340667, longitude: 126.734094, icon: defaultIcon },
  // 시흥비즈니스센터
  비즈: { latitude: 37.340004, longitude: 126.732361, icon: defaultIcon },
  // '미래', '제2생' 은 좌표 미확인 — 현재 시간표에 강의가 없어 응답에도 없음
};

const names = Object.keys(buildingLocations);

export function buildingOrder(name: string): number {
  const i = names.indexOf(name);
  return i < 0 ? names.length : i;
}

export const buildingIcon = (name: string): number => buildingLocations[name]?.icon ?? defaultIcon;
