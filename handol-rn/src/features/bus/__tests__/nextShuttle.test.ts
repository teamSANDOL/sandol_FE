import { calculateNextShuttle, countdownText, remainLabel, upcomingEntries, withTransfer } from '../nextShuttle';
import { headline, isActive, type ShuttleEntry, type ShuttleTimetable } from '../model';
import { computeConnections } from '../transfer';

const fixed = (h: number, m: number): ShuttleEntry => ({ type: 'fixed', start: h * 60 + m });
const flex = (a: number, b: number): ShuttleEntry => ({ type: 'flexible', start: a * 60, end: b * 60 });
const tt = (entries: ShuttleEntry[]): ShuttleTimetable => ({ direction: 'schoolToJeongwang', dayType: 'weekday', entries });
const at = (h: number, m: number) => h * 60 + m;

describe('calculateNextShuttle', () => {
  const table = tt([flex(8, 10), fixed(10, 0), fixed(10, 30), flex(17, 18), fixed(18, 0)]);

  it('시간표가 없으면 미운행', () => {
    const n = calculateNextShuttle(null, at(9, 0));
    expect(n.status).toBe('notOperating');
    expect(isActive(n)).toBe(false);
    expect(headline(n)).toBe('운행 안함');
  });

  it('구간 안이면 수시운행', () => {
    const n = calculateNextShuttle(table, at(9, 0));
    expect(n).toMatchObject({ status: 'flexible', subText: '08:00~10:00 수시운행' });
  });

  it('구간 시작 전에는 시작 시각까지 대기로 안내', () => {
    const n = calculateNextShuttle(table, at(6, 0));
    expect(n).toMatchObject({ status: 'upcoming', remainMinutes: 120, subText: '08:00부터 수시운행' });
    expect(headline(n)).toBe('08:00 출발');
  });

  it('구간 끝 시각 정각에는 다음 정시편(반열린구간)', () => {
    const n = calculateNextShuttle(table, at(18, 0));
    expect(n).toMatchObject({ status: 'upcoming', remainMinutes: 0 });
    expect(headline(n)).toBe('곧 출발');
  });

  it('20분 이내면 N분 뒤 출발, 밖이면 HH:MM 출발', () => {
    expect(headline(calculateNextShuttle(table, at(10, 11)))).toBe('19분 뒤 출발');
    expect(calculateNextShuttle(table, at(10, 11)).subText).toBe('10:30 출발');
    const far = calculateNextShuttle(table, at(10, 5));
    expect(headline(far)).toBe('10:30 출발');
    expect(far.subText).toBeUndefined();
  });

  it('막차 이후에는 운행 종료', () => {
    const n = calculateNextShuttle(table, at(18, 1));
    expect(n).toMatchObject({ status: 'closed', statusLabel: '운행 종료' });
  });

  it('도착버스 탑승 구간', () => {
    const t = tt([{ type: 'arrivalBoarding', start: at(17, 0), end: at(22, 17), boardingNote: '정류장' }]);
    expect(calculateNextShuttle(t, at(20, 0))).toMatchObject({ status: 'arrivalBoarding', subText: '정류장 · 막차 22:17' });
  });
});

describe('upcomingEntries', () => {
  it('진행 중인 구간을 포함해 최대 count 개', () => {
    const t = tt([fixed(8, 0), flex(9, 11), fixed(11, 0), fixed(12, 0), fixed(13, 0)]);
    expect(upcomingEntries(t, at(10, 0), 3).map((e) => e.start)).toEqual([9 * 60, 11 * 60, 12 * 60]);
    expect(upcomingEntries(null, 0)).toEqual([]);
  });
});

describe('countdown / labels', () => {
  it('초 단위 카운트다운', () => {
    expect(countdownText(at(9, 5), at(9, 2), 48)).toBe('2분 12초 뒤 출발');
    expect(countdownText(at(9, 5), at(9, 4), 30)).toBe('30초 뒤 출발');
    expect(countdownText(at(9, 5), at(9, 3), 0)).toBe('2분 뒤 출발');
    expect(countdownText(at(9, 5), at(9, 5), 0)).toBe('곧 출발');
  });
  it('remainLabel', () => {
    expect(remainLabel(39)).toBe('39분');
    expect(remainLabel(120)).toBe('2시간');
    expect(remainLabel(279)).toBe('4시간 39분');
  });
});

describe('withTransfer', () => {
  const first = tt([fixed(9, 0), fixed(10, 0)]);
  const second = tt([fixed(9, 30), fixed(10, 40)]);
  const transfers = computeConnections(first, second, at(8, 0));

  it('직행이 운행 중이면 그대로', () => {
    const d = calculateNextShuttle(tt([fixed(9, 0)]), at(8, 55));
    expect(withTransfer(d, transfers)).toBe(d);
  });
  it('직행이 없으면 환승 안내', () => {
    const n = withTransfer(calculateNextShuttle(null, at(8, 0)), transfers);
    expect(n.statusLabel).toBe('직행 없음 · 환승 이용');
    expect(n.subText).toBe('09:00 출발 → 본교 09:30 환승');
    expect(isActive(n)).toBe(true);
  });
  it('직행이 끝났으면 직행 종료', () => {
    const n = withTransfer(calculateNextShuttle(tt([fixed(7, 0)]), at(8, 0)), transfers);
    expect(n.statusLabel).toBe('직행 종료 · 환승 이용');
  });
  it('환승이 없으면 직행 결과 유지', () => {
    const d = calculateNextShuttle(null, at(8, 0));
    expect(withTransfer(d, null)).toBe(d);
    expect(withTransfer(d, [])).toBe(d);
  });
});
