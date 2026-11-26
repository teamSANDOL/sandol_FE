import {
  dayChips,
  defaultFor,
  forDay,
  hourLabel,
  isAfterClassDay,
  nearestTickIndex,
  setDay,
  setRangeByTick,
  syncToNow,
  ticksFor,
  timeLabel,
  todaySelectable,
} from '../query';
import { allPeriods, periodLabelOf } from '../periods';

const mon = (h: number, m = 0) => ({ weekday: 1, minutes: h * 60 + m });

describe('ticksFor', () => {
  it('지금 이후의 교시 시작·끝 시각만 칸으로 둔다', () => {
    const ticks = ticksFor(13 * 60 + 52);
    expect(ticks[0]).toBe(13 * 60 + 52);
    expect(ticks[1]).toBe(14 * 60 + 20);
    expect(ticks[ticks.length - 1]).toBe(22 * 60 + 30);
  });
  it('밤늦게 칸이 없으면 30분 뒤를 붙인다', () => {
    expect(ticksFor(23 * 60 + 30)).toEqual([23 * 60 + 30, 23 * 60 + 50]);
  });
});

describe('기본 구간', () => {
  it('오늘이면 지금부터 2시간에 가장 가까운 칸까지', () => {
    const q = defaultFor(mon(13, 52));
    expect(q.daysAhead).toBe(0);
    expect(q.startMinutes).toBe(13 * 60 + 52);
    expect(q.endMinutes).toBe(15 * 60 + 30);
    expect(timeLabel(q)).toBe('13:52 ~ 15:30');
  });
  it('마지막 교시가 시작하면 내일로 넘긴다', () => {
    expect(todaySelectable(21 * 60 + 40)).toBe(false);
    const q = defaultFor(mon(22, 0));
    expect(q.daysAhead).toBe(1);
    expect(q.weekday).toBe(2);
    expect(q.startMinutes).toBe(9 * 60 + 30);
  });
  it('일요일 + 1일은 월요일', () => {
    expect(forDay({ weekday: 7, minutes: 600 }, 1).weekday).toBe(1);
  });
});

describe('날짜·구간 변경', () => {
  it('setRangeByTick 은 최소 한 칸을 유지한다', () => {
    const q = defaultFor(mon(9, 0));
    const next = setRangeByTick(q, 3, 3);
    expect(next.endMinutes).toBeGreaterThan(next.startMinutes);
  });
  it('setDay 는 고른 구간을 새 축의 가까운 칸에 맞춘다', () => {
    const q = defaultFor(mon(9, 0));
    const next = setDay(q, mon(9, 0), 2);
    expect(next.daysAhead).toBe(2);
    expect(next.weekday).toBe(3);
    expect(next.startMinutes).toBeLessThan(next.endMinutes);
  });
  it('같은 날이면 그대로', () => {
    const q = defaultFor(mon(9, 0));
    expect(setDay(q, mon(9, 0), 0)).toBe(q);
  });
});

describe('syncToNow', () => {
  it('10분 미만이면 그대로', () => {
    const q = defaultFor(mon(10, 0));
    expect(syncToNow(q, mon(10, 5))).toBe(q);
  });
  it('시작을 지금에 두었으면 새 지금을 따라온다', () => {
    const q = defaultFor(mon(10, 0));
    const next = syncToNow(q, mon(10, 40));
    expect(next.anchorMinutes).toBe(10 * 60 + 40);
    expect(next.startMinutes).toBe(10 * 60 + 40);
  });
  it('자정을 넘겨 요일이 바뀌면 처음부터', () => {
    const q = defaultFor(mon(10, 0));
    expect(syncToNow(q, { weekday: 2, minutes: 600 }).weekday).toBe(2);
  });
  it('오늘 칸이 끝나면 내일로', () => {
    const q = defaultFor(mon(21, 0));
    expect(syncToNow(q, mon(21, 50)).daysAhead).toBe(1);
  });
});

describe('표시', () => {
  it('hourLabel', () => {
    expect(hourLabel(9 * 60)).toBe('09시');
    expect(hourLabel(22 * 60 + 30)).toBe('22시 30분');
  });
  it('nearestTickIndex', () => {
    expect(nearestTickIndex([0, 10, 20], 12)).toBe(1);
  });
  it('isAfterClassDay', () => {
    expect(isAfterClassDay(defaultFor(mon(23, 0)))).toBe(false);
  });
  it('dayChips: 7칸, 첫 칸은 오늘', () => {
    const chips = dayChips(new Date(Date.UTC(2026, 10, 24, 11, 0)));
    expect(chips).toHaveLength(7);
    expect(chips[0]).toMatchObject({ top: '오늘', date: 24, enabled: true });
    expect(chips[1].top).toBe('내일');
  });
  it('dayChips: 21:40 이후 오늘은 비활성', () => {
    const chips = dayChips(new Date(Date.UTC(2026, 10, 24, 22, 0)));
    expect(chips[0].enabled).toBe(false);
    expect(chips[1].enabled).toBe(true);
  });
});

describe('periodLabelOf', () => {
  it('교시·전체·시각 구간', () => {
    expect(periodLabelOf(9 * 60 + 30, 10 * 60 + 20)).toBe('1교시');
    expect(periodLabelOf(allPeriods.start, allPeriods.end)).toBe('전체 교시');
    expect(periodLabelOf(600, 700)).toBeNull();
  });
});
