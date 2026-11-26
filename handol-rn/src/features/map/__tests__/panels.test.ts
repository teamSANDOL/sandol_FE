import { COLLAPSED_H, fracOf, maxFracOf, minFracOf, nextOnBack, pickSnapTarget } from '../panels';

describe('시트 높이', () => {
  it('첫 시트는 중간 높이가 최대', () => {
    expect(maxFracOf('home')).toBe(0.42);
    expect(maxFracOf('emptyClass')).toBe(0.9);
  });
  it('패널별 열림 높이', () => {
    expect(fracOf('home', false)).toBe(0.268);
    expect(fracOf('tuk', false)).toBe(0.38);
    expect(fracOf('tuk', true)).toBe(0.55);
    expect(fracOf('tukDetail', false)).toBe(0.9);
  });
  it('접힘 높이는 120px, 비율은 0.08~0.35', () => {
    expect(minFracOf(1000)).toBeCloseTo(COLLAPSED_H / 1000);
    expect(minFracOf(200)).toBe(0.35);
    expect(minFracOf(5000)).toBe(0.08);
  });
});

describe('nextOnBack', () => {
  const ctx = { hasBuilding: true, hasTukCategory: true };
  it('첫 시트는 막지 않는다', () => expect(nextOnBack('home', ctx)).toEqual({ type: 'none' }));
  it('건물 시트는 선택을 풀고 첫 시트로', () =>
    expect(nextOnBack('building', ctx)).toEqual({ type: 'show', panel: 'home', clearBuilding: true }));
  it('빈 강의실은 건물이 있으면 건물로', () => {
    expect(nextOnBack('emptyClass', ctx)).toEqual({ type: 'show', panel: 'building' });
    expect(nextOnBack('emptyClass', { ...ctx, hasBuilding: false })).toEqual({ type: 'show', panel: 'home' });
  });
  it('TUK 분류를 고른 상태면 분류부터 푼다', () => {
    expect(nextOnBack('tuk', ctx)).toEqual({ type: 'clearTukCategory' });
    expect(nextOnBack('tuk', { ...ctx, hasTukCategory: false })).toEqual({ type: 'show', panel: 'home' });
  });
  it('업체 상세는 선택을 풀고 목록으로', () =>
    expect(nextOnBack('tukDetail', ctx)).toEqual({ type: 'show', panel: 'tuk', clearPlace: true }));
});

describe('pickSnapTarget', () => {
  it('느리면 가장 가까운 정지점', () => {
    expect(pickSnapTarget(0.5, 0, 0.15, 0.9)).toBe(0.42);
    expect(pickSnapTarget(0.8, 0.2, 0.15, 0.9)).toBe(0.9);
    expect(pickSnapTarget(0.2, -0.2, 0.15, 0.9)).toBe(0.15);
  });
  it('빠른 플링은 진행 방향의 다음 정지점', () => {
    expect(pickSnapTarget(0.3, 1.5, 0.15, 0.9)).toBe(0.42);
    expect(pickSnapTarget(0.42, 1.5, 0.15, 0.9)).toBe(0.9);
    expect(pickSnapTarget(0.9, -1.5, 0.15, 0.9)).toBe(0.42);
    expect(pickSnapTarget(0.42, -1.5, 0.15, 0.9)).toBe(0.15);
  });
  it('첫 시트(최대=중간)는 정지점 둘뿐', () => {
    expect(pickSnapTarget(0.3, 1.5, 0.15, 0.42)).toBe(0.42);
  });
});
