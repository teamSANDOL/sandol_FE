import { buildEmptyClasses, toRoomMap } from '../mapping';
import { mergedOrder, moveItem, sortNearby, walkMinutes, defaultSortSettings, type BuildingSortSettings } from '../sort';
import { parseSettings } from '../sortStore';

const avail = [
  { building: 'E동', empty_classrooms: ['302호', '101호'] },
  { building: 'A동', empty_classrooms: ['201호'] },
  { building: '미확인', empty_classrooms: ['1호'] },
];
const rooms = toRoomMap([
  { building: 'E동', classrooms: ['302호', '101호', '101호', '205호'] },
  { building: 'A동', classrooms: ['201호'] },
  { building: 'B동', classrooms: ['110호'] },
]);

describe('buildEmptyClasses', () => {
  const list = buildEmptyClasses(avail, rooms);
  it('빈 호실 정렬 · 전체 목록 합침', () => {
    const e = list.find((x) => x.className === 'E동')!;
    expect(e.classList).toEqual(['101호', '302호']);
    expect(e.allRooms).toEqual(['101호', '205호', '302호']);
    expect(e.emptyCount).toBe(2);
    expect(e.totalCount).toBe(3);
  });
  it('응답에 없는 건물은 0개로 채운다', () => {
    const b = list.find((x) => x.className === 'B동')!;
    expect(b.emptyCount).toBe(0);
    expect(b.allRooms).toEqual(['110호']);
  });
  it('캠퍼스 순회 순서 · 좌표 없는 건물은 뒤', () => {
    expect(list.map((x) => x.className)).toEqual(['A동', 'B동', 'E동', '미확인']);
    expect(list[3].latitude).toBeNull();
  });
});

describe('sortNearby', () => {
  const classes = buildEmptyClasses(avail, rooms);
  const here = { latitude: 37.3397, longitude: 126.735 }; // E동 근처
  const names = (s: BuildingSortSettings, pos: typeof here | null) =>
    sortNearby(classes, pos, s).map((x) => x.building.className);

  it('거리순: 가까운 건물 먼저, 좌표 없는 건물은 뒤', () => {
    const order = names(defaultSortSettings, here);
    expect(order[0]).toBe('E동');
    expect(order[order.length - 1]).toBe('미확인');
  });
  it('위치를 모르면 빈 강의실 많은 순', () => {
    expect(names(defaultSortSettings, null)[0]).toBe('E동');
  });
  it('count 정렬: 같으면 캠퍼스 순서', () => {
    expect(names({ mode: 'count', customOrder: [] }, here)).toEqual(['E동', 'A동', '미확인', 'B동']);
  });
  it('custom 정렬: 저장된 순서 우선', () => {
    expect(names({ mode: 'custom', customOrder: ['B동', 'A동'] }, here).slice(0, 2)).toEqual(['B동', 'A동']);
  });
  it('walkMinutes: 70m/분 올림, 최소 1', () => {
    const b = classes[0];
    expect(walkMinutes({ building: b, distanceMeters: 71 })).toBe(2);
    expect(walkMinutes({ building: b, distanceMeters: 1 })).toBe(1);
    expect(walkMinutes({ building: b, distanceMeters: null })).toBeNull();
  });
});

describe('순서 편집', () => {
  it('mergedOrder: 저장된 것 앞, 새 건물 뒤, 사라진 건물 제외', () => {
    expect(mergedOrder({ mode: 'custom', customOrder: ['B', 'X', 'A'] }, ['A', 'B', 'C'])).toEqual(['B', 'A', 'C']);
  });
  it('moveItem: 아래로 옮길 때 to-1 에 삽입', () => {
    expect(moveItem(['a', 'b', 'c', 'd'], 0, 3)).toEqual(['b', 'c', 'a', 'd']);
    expect(moveItem(['a', 'b', 'c', 'd'], 3, 1)).toEqual(['a', 'd', 'b', 'c']);
  });
  it('parseSettings: 잘못된 값은 기본값', () => {
    expect(parseSettings('nope', '{bad')).toEqual(defaultSortSettings);
    expect(parseSettings('count', '["A동"]')).toEqual({ mode: 'count', customOrder: ['A동'] });
  });
});