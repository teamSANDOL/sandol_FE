import type { EmptyClass } from '@/features/empty_class/model';
import { floorOf, groupByFloor, roomsWithStatus, visibleRows } from '../roomStatus';
import { bubbleLayout, estimateTextWidth } from '../markerSize';
import { searchPlaces } from '../search';
import { resolveRemoteUrl, tukIconOf, tukMatches, toTukPlace } from '../tukWorld';

const building = (name: string, empty: string[], all: string[]): EmptyClass => ({
  className: name,
  icon: 0,
  classList: empty,
  emptyCount: empty.length,
  latitude: 1,
  longitude: 2,
  totalCount: all.length,
  allRooms: all,
});

describe('호실 상태', () => {
  const b = building('E동', ['101호'], ['101호', '205호', '관리실']);
  it('전체 목록이 있으면 빈 호실 외는 수업예정', () => {
    expect(roomsWithStatus(b)).toEqual([
      { room: '101호', status: 'empty' },
      { room: '205호', status: 'busy' },
      { room: '관리실', status: 'busy' },
    ]);
  });
  it('전체 목록이 없으면 빈 호실만', () => {
    expect(roomsWithStatus(building('A동', ['1호'], []))).toEqual([{ room: '1호', status: 'empty' }]);
  });
  it('층 계산 · 기타는 마지막', () => {
    expect(floorOf('217호')).toBe('2층');
    expect(groupByFloor(roomsWithStatus(b)).map((g) => g.floor)).toEqual(['1층', '2층', '기타']);
  });
  it('검색: 건물명이면 전체, 아니면 호실만', () => {
    const items = [b, building('A동', ['201호'], ['201호'])];
    expect(visibleRows(items, 'E동', 'building').map((r) => r.building.className)).toEqual(['E동']);
    const hit = visibleRows(items, 'E동205', 'building');
    expect(hit).toHaveLength(1);
    expect(hit[0].rooms.map((r) => r.room)).toEqual(['205호']);
    expect(visibleRows(items, '', 'count').map((r) => r.building.className)).toEqual(['E동', 'A동']);
  });
});

describe('TUK 월드', () => {
  it('상대 경로 이미지는 base 기준으로 푼다', () => {
    expect(resolveRemoteUrl('/static/a.png', 'https://sandori.kr')).toBe('https://sandori.kr/static/a.png');
    expect(resolveRemoteUrl('https://cdn.x/a.png', 'https://sandori.kr')).toBe('https://cdn.x/a.png');
  });
  const place = toTukPlace(
    { id: 1, name: '맛집', category: '술집', latitude: 1, longitude: 2, discount_info: '10%', images: [{ url: '/a.png' }] },
    'https://sandori.kr',
  );
  it('DTO 매핑', () => {
    expect(place).toMatchObject({ discountInfo: '10%', address: null, imageUrls: ['https://sandori.kr/a.png'] });
  });
  it('분류 필터 · 모르는 분류는 식당 아이콘', () => {
    expect(tukMatches('all', place)).toBe(true);
    expect(tukMatches('bar', place)).toBe(true);
    expect(tukMatches('food', place)).toBe(false);
    expect(tukIconOf({ ...place, category: '기타' })).toBe('restaurant');
  });
  it('검색 결과 구성', () => {
    const r = searchPlaces('동', [building('E동', ['1'], [])], [{ ...place, name: '동네맛집' }]);
    expect(r.map((x) => x.sub)).toEqual(['빈 강의실 1개', 'TUK 월드 · 술집']);
  });
});

describe('마커 크기', () => {
  it('한글은 글자 크기에 가깝고 굵으면 더 넓다', () => {
    expect(estimateTextWidth('빈 강의실 17개', 12)).toBeGreaterThan(estimateTextWidth('B동', 12));
    expect(estimateTextWidth('B동', 15, true)).toBeGreaterThan(estimateTextWidth('B동', 15));
  });
  it('꼬리 앵커: 가운데 / 오른쪽 끝', () => {
    const mid = bubbleLayout('B동', 20, false);
    expect(mid.anchor.x).toBeCloseTo(0.5);
    const right = bubbleLayout('A동', 17, true);
    expect(right.anchor.x).toBeGreaterThan(0.5);
    expect(right.anchor.y).toBeLessThan(1);
  });
});