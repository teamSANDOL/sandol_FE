/** 시트에 무엇을 보여줄지. TUK 월드 시트면 상단 탭도 'TUK 월드'다. */
export type Panel = 'home' | 'filter' | 'building' | 'buildingDetail' | 'emptyClass' | 'tuk' | 'tukDetail';

/** 시트 높이 3단 (본문 높이 비율). 접힘만 픽셀 기준이다. */
export const COLLAPSED_H = 120;
export const SNAP_FRAC = 0.42;
export const MAX_FRAC = 0.9;
/** 이보다 높이 올라가면 지도를 덮고 '지도' 라벨을 보여준다. */
export const COVER_FRAC = 0.7;

export const isTukPanel = (p: Panel): boolean => p === 'tuk' || p === 'tukDetail';

/** 첫 시트는 타일 한 줄뿐이라 끝까지 올리면 화면 대부분이 비므로 중간 높이에서 멈춘다. */
export const maxFracOf = (p: Panel): number => (p === 'home' ? SNAP_FRAC : MAX_FRAC);

/** 패널을 열 때 시트가 멈출 높이 */
export function fracOf(p: Panel, hasTukCategory: boolean): number {
  switch (p) {
    case 'home':
      // Figma 맵 2:4976: 시트 윗선 656, 아래 탭 윗선 847 → 191dp. 기기 본문 713dp 기준 비율 (타일 한 줄 높이)
      return 0.268;
    case 'filter':
      return SNAP_FRAC;
    case 'building':
      return 0.55;
    case 'tuk':
      return hasTukCategory ? 0.55 : 0.38;
    default:
      return MAX_FRAC;
  }
}

export const minFracOf = (bodyH: number): number => Math.min(Math.max(COLLAPSED_H / bodyH, 0.08), 0.35);

export type BackAction =
  | { type: 'none' }
  | { type: 'show'; panel: Panel; clearBuilding?: boolean; clearPlace?: boolean }
  | { type: 'clearTukCategory' };

/** 시스템 뒤로가기 · 시트의 뒤로 버튼. 첫 시트에서는 막지 않아 셸이 홈 탭으로 돌린다. */
export function nextOnBack(panel: Panel, ctx: { hasBuilding: boolean; hasTukCategory: boolean }): BackAction {
  switch (panel) {
    case 'home':
      return { type: 'none' };
    case 'filter':
    case 'building':
      return { type: 'show', panel: 'home', clearBuilding: true };
    case 'buildingDetail':
      return { type: 'show', panel: 'building' };
    case 'emptyClass':
      return { type: 'show', panel: ctx.hasBuilding ? 'building' : 'home' };
    case 'tuk':
      return ctx.hasTukCategory ? { type: 'clearTukCategory' } : { type: 'show', panel: 'home' };
    case 'tukDetail':
      return { type: 'show', panel: 'tuk', clearPlace: true };
  }
}

/**
 * 손잡이 드래그를 놓았을 때 멈출 높이(본문 비율). velocity 는 위로 올리는 방향이 양수(비율/초).
 * 빠른 플링은 진행 방향의 다음 정지점으로, 느리면 가장 가까운 정지점으로.
 */
export function pickSnapTarget(cur: number, velocity: number, minFrac: number, maxFrac: number): number {
  'worklet'; // 시트 드래그를 놓을 때 UI 스레드에서 부른다
  const stops = [...new Set([minFrac, SNAP_FRAC, maxFrac])].filter((s) => s <= maxFrac).sort((a, b) => a - b);
  if (Math.abs(velocity) > 0.9) {
    if (velocity > 0) return stops.find((s) => s > cur + 0.01) ?? maxFrac;
    return [...stops].reverse().find((s) => s < cur - 0.01) ?? minFrac;
  }
  return stops.reduce((a, b) => (Math.abs(a - cur) <= Math.abs(b - cur) ? a : b));
}
