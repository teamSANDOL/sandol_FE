import { useState } from 'react';
import type { EmptyClass } from '@/features/empty_class/model';
import { hasLocation } from '@/features/empty_class/model';
import { fracOf, isTukPanel, maxFracOf, nextOnBack, type Panel } from './panels';
import type { TukCategory, TukPlace } from './tukWorld';

interface Deps {
  buildings: readonly EmptyClass[];
  animateTo: (frac: number) => Promise<void>;
  currentFrac: () => number;
  moveCamera: (latitude: number, longitude: number) => void;
}

/**
 * 맵 탭의 시트 상태 기계: 어떤 패널을 보여주는지, 고른 건물 · TUK 분류 · 업체, 그리고
 * 패널을 바꿀 때 시트를 어느 높이로 옮기는지.
 */
export function useMapState({ buildings, animateTo, currentFrac, moveCamera }: Deps) {
  const [panel, setPanel] = useState<Panel>('home');
  const [buildingName, setBuildingName] = useState<string | null>(null);
  const [tukCategory, setTukCategoryState] = useState<TukCategory | null>(null);
  const [place, setPlace] = useState<TukPlace | null>(null);
  /** 빈 강의실 시트가 다 올라온 뒤 스크롤할 건물 */
  const [focusBuilding, setFocusBuilding] = useState<string | null>(null);

  /** 시트 내용을 바꾸고 그 내용에 맞는 높이로 올린다. */
  const show = async (p: Panel, category: TukCategory | null = tukCategory): Promise<void> => {
    const frac = fracOf(p, category !== null);
    // 새 패널의 최대 높이보다 높이 올라가 있으면 먼저 내린다. 한 번에 줄이면 높이가 뚝 떨어진다.
    if (currentFrac() > maxFracOf(p)) await animateTo(frac);
    setPanel(p);
    setFocusBuilding(null);
    requestAnimationFrame(() => void animateTo(frac));
  };

  const selectBuilding = (name: string | null): void => {
    if (name === buildingName) return;
    setBuildingName(name);
    const b = buildings.find((x) => x.className === name);
    if (b && hasLocation(b)) moveCamera(b.latitude, b.longitude);
  };

  const selectPlace = (p: TukPlace | null): void => {
    setPlace(p);
    if (p) moveCamera(p.latitude, p.longitude);
  };

  const setTukCategory = (c: TukCategory | null): void => {
    setTukCategoryState(c);
    void animateTo(fracOf('tuk', c !== null));
  };

  const openBuilding = (b: EmptyClass): void => {
    selectBuilding(b.className);
    void show('building');
  };

  const openPlace = (p: TukPlace): void => {
    selectPlace(p);
    void show('tukDetail');
  };

  /** 빈 강의실 현황을 열고, 시트가 다 올라오면 building 카드로 스크롤한다. */
  const openEmptyClass = async (building?: string): Promise<void> => {
    if (building) selectBuilding(building);
    await show('emptyClass');
    if (building) setFocusBuilding(building);
  };

  const deselectToHome = (): void => {
    selectBuilding(null);
    void show('home');
  };

  /** 시스템 뒤로가기 · 시트의 뒤로 버튼. 처리했으면 true */
  const back = (): boolean => {
    const action = nextOnBack(panel, { hasBuilding: buildingName !== null, hasTukCategory: tukCategory !== null });
    if (action.type === 'none') return false;
    if (action.type === 'clearTukCategory') {
      setTukCategory(null);
      return true;
    }
    if (action.clearBuilding) selectBuilding(null);
    if (action.clearPlace) selectPlace(null);
    void show(action.panel);
    return true;
  };

  return {
    panel,
    isTuk: isTukPanel(panel),
    buildingName,
    tukCategory,
    place,
    focusBuilding,
    show,
    back,
    selectBuilding,
    selectPlace,
    setTukCategory,
    openBuilding,
    openPlace,
    openEmptyClass,
    deselectToHome,
  };
}
