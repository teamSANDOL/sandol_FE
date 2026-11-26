import type { ShuttleEntry, ShuttleTimetable } from '../model';
import { computeConnections, legsOf } from '../transfer';

const fixed = (h: number, m: number): ShuttleEntry => ({ type: 'fixed', start: h * 60 + m });
const tt = (entries: ShuttleEntry[]): ShuttleTimetable => ({ direction: 'jeongwangToSchool', dayType: 'weekday', entries });
const at = (h: number, m: number) => h * 60 + m;

describe('legsOf', () => {
  it('본교를 거치는 방향만 1구간 · 2구간을 준다', () => {
    expect(legsOf('jeongwangToCampus2')).toEqual(['jeongwangToSchool', 'schoolToCampus2']);
    expect(legsOf('campus2ToJeongwang')).toEqual(['campus2ToSchool', 'schoolToJeongwang']);
    expect(legsOf('schoolToJeongwang')).toBeNull();
  });
});

describe('computeConnections', () => {
  it('시간표가 없으면 빈 목록', () => {
    expect(computeConnections(null, tt([]), 0)).toEqual([]);
    expect(computeConnections(tt([]), null, 0)).toEqual([]);
  });

  it('20분 이상 간격이면 안전 연결, 같은 환승편은 늦게 출발하는 1구간만', () => {
    const first = tt([fixed(8, 50), fixed(9, 0)]);
    const second = tt([fixed(9, 30)]);
    const res = computeConnections(first, second, at(8, 0));
    // 8:50+20=9:10 → 9:30, 9:00+20=9:20 → 9:30. 늦은 9:00 이 남는다
    const safe = res.filter((c) => !c.tight);
    expect(safe).toHaveLength(1);
    expect(safe[0]).toMatchObject({ departure: at(9, 0), transfer: at(9, 30), tight: false });
  });

  it('간격이 10~20분이면 빠듯한 연결', () => {
    const first = tt([fixed(9, 0), fixed(9, 15)]);
    const second = tt([fixed(9, 30), fixed(10, 30)]);
    const res = computeConnections(first, second, at(8, 0));
    expect(res.find((c) => c.departure === at(9, 0))).toMatchObject({ transfer: at(9, 30), tight: false });
    expect(res.find((c) => c.departure === at(9, 15))).toMatchObject({ transfer: at(9, 30), tight: true });
    // 안전 연결(9:00→9:30, 9:15→10:30)과 빠듯한 연결(9:15→9:30)이 출발 시각순으로 섞인다
    expect(res.map((c) => [c.departure, c.transfer, c.tight])).toEqual([
      [at(9, 0), at(9, 30), false],
      [at(9, 15), at(9, 30), true],
      [at(9, 15), at(10, 30), false],
    ]);
  });

  it('이미 지난 1구간은 제외', () => {
    const res = computeConnections(tt([fixed(7, 0)]), tt([fixed(9, 0)]), at(8, 0));
    expect(res).toEqual([]);
  });

  it('수시운행 1구간은 지금(또는 구간 시작) 탄다고 계산', () => {
    const flex: ShuttleEntry = { type: 'flexible', start: at(8, 40), end: at(10, 0) };
    const second = tt([fixed(9, 30), fixed(11, 0)]);
    const during = computeConnections(tt([flex]), second, at(9, 0));
    // 지금(9:00)+20 = 9:20 이후 첫 편 9:30
    expect(during[0]).toMatchObject({ departure: at(9, 0), transfer: at(9, 30), tight: false });
  });

  it('2구간이 수시운행이면 구간 안에서 바로 탄다', () => {
    const second = tt([{ type: 'flexible', start: at(9, 0), end: at(12, 0) }]);
    const res = computeConnections(tt([fixed(9, 0)]), second, at(8, 0));
    // 9:20 에 구간 안에서 바로 탄다(안전). 구간 안이라 10분 뒤 9:10 도 빠듯한 연결로 함께 나온다
    expect(res.find((c) => !c.tight)).toMatchObject({ departure: at(9, 0), transfer: at(9, 20) });
    expect(res.find((c) => c.tight)).toMatchObject({ departure: at(9, 0), transfer: at(9, 10) });
  });

  it('count 개로 제한', () => {
    const first = tt([fixed(9, 0), fixed(10, 0), fixed(11, 0), fixed(12, 0)]);
    const second = tt([fixed(9, 30), fixed(10, 30), fixed(11, 30), fixed(12, 30)]);
    expect(computeConnections(first, second, 0, 2).filter((c) => !c.tight)).toHaveLength(2);
  });
});
