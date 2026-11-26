import { COVERED_YEARS, coversYear, isHoliday } from '../holidays';
import { buildBoard, timetableOf } from '../board';
import { ALL_DIRECTIONS, directionBetween, reversedDirection } from '../model';
import { BUILTIN_STOPS, builtinTimetable, dayTypeOf } from '../scheduleData';

/** KST 벽시계 Date (getUTC* 가 한국 시각) */
const kst = (y: number, mo: number, d: number, h = 0, mi = 0) => new Date(Date.UTC(y, mo - 1, d, h, mi));

describe('공휴일 · 요일 구분', () => {
  it('대체공휴일 포함 공휴일 판정', () => {
    expect(isHoliday(kst(2026, 3, 2))).toBe(true); // 삼일절 대체
    expect(isHoliday(kst(2026, 10, 5))).toBe(true); // 개천절 대체
    expect(isHoliday(kst(2027, 12, 27))).toBe(true);
    expect(isHoliday(kst(2026, 3, 3))).toBe(false);
  });
  it('공휴일이면 주말이어도 holiday', () => {
    expect(dayTypeOf(kst(2026, 10, 3))).toBe('holiday'); // 토요일 개천절
    expect(dayTypeOf(kst(2026, 5, 24))).toBe('holiday'); // 일요일
  });
  it('요일로 판정', () => {
    expect(dayTypeOf(kst(2026, 11, 24))).toBe('weekday'); // 화
    expect(dayTypeOf(kst(2026, 11, 28))).toBe('saturday');
    expect(dayTypeOf(kst(2026, 11, 29))).toBe('sunday');
  });
  it('목록 밖 연도는 요일만으로 판정(공휴일을 평일로 취급)', () => {
    expect(coversYear(kst(2028, 1, 1))).toBe(false);
    expect(dayTypeOf(kst(2028, 1, 3))).toBe('weekday');
  });
  it('공휴일 목록이 앞으로 180일을 덮는다 (갱신 알림)', () => {
    const later = new Date(Date.now() + 180 * 86_400_000 + 9 * 3_600_000);
    expect(COVERED_YEARS.has(later.getUTCFullYear())).toBe(true);
  });
});

describe('방향', () => {
  it('여섯 방향은 (출발, 도착) 조합과 1:1 이고 reversed 가 짝이다', () => {
    expect(ALL_DIRECTIONS).toHaveLength(6);
    expect(directionBetween('main_campus', 'main_campus')).toBeNull();
    expect(reversedDirection('schoolToJeongwang')).toBe('jeongwangToSchool');
    expect(reversedDirection('jeongwangToCampus2')).toBe('campus2ToJeongwang');
    for (const d of ALL_DIRECTIONS) expect(reversedDirection(reversedDirection(d))).toBe(d);
  });
});

describe('내장 시간표', () => {
  it('노선1 은 평일 전용', () => {
    expect(builtinTimetable('schoolToJeongwang', 'weekday')?.entries.length).toBeGreaterThan(30);
    expect(builtinTimetable('schoolToJeongwang', 'saturday')).toBeNull();
    expect(builtinTimetable('jeongwangToSchool', 'holiday')).toBeNull();
  });
  it('노선2 는 평일 · 토요일만, 방향별로 다르다', () => {
    expect(builtinTimetable('schoolToCampus2', 'weekday')).not.toBeNull();
    expect(builtinTimetable('schoolToCampus2', 'saturday')).toBeNull();
    expect(builtinTimetable('campus2ToJeongwang', 'saturday')).not.toBeNull();
    expect(builtinTimetable('campus2ToJeongwang', 'weekday')).toBeNull();
    expect(builtinTimetable('jeongwangToCampus2', 'sunday')).toBeNull();
  });
  it('시간표는 시작 시각 오름차순', () => {
    for (const d of ALL_DIRECTIONS) {
      const t = builtinTimetable(d, 'weekday');
      if (!t) continue;
      const starts = t.entries.map((e) => e.start);
      expect([...starts].sort((a, b) => a - b)).toEqual(starts);
    }
  });
});

describe('buildBoard (내장 시간표)', () => {
  it('평일 08:55 학교 → 정왕역: 09:00 이 다음 출발', () => {
    const b = buildBoard(null, 'schoolToJeongwang', kst(2026, 11, 24, 8, 55));
    expect(b.next).toMatchObject({ status: 'upcoming', remainMinutes: 5, departureMinutes: 540 });
    expect(b.transfers).toBeNull();
    expect(b.upcoming[0].start).toBe(540);
  });
  it('일요일 정왕역 → 제2캠퍼스는 직행 · 환승 모두 없어 운행 안함', () => {
    const b = buildBoard(null, 'jeongwangToCampus2', kst(2026, 11, 29, 9, 0));
    expect(b.next.status).toBe('notOperating');
    expect(b.transfers).toEqual([]);
  });
  it('평일 저녁 제2캠퍼스행 직행 종료 후 환승 안내가 없으면 직행 종료 그대로', () => {
    const b = buildBoard(null, 'jeongwangToCampus2', kst(2026, 11, 24, 20, 0));
    expect(b.next.status).toBe('closed');
  });
  it('timetableOf 는 공휴일에 내장 노선1 을 돌려주지 않는다', () => {
    expect(timetableOf(null, 'schoolToJeongwang', kst(2026, 3, 2, 10))).toBeNull();
  });
  it('정류장 상수', () => {
    expect(BUILTIN_STOPS.main_campus.name).toBe('한국공학대 정문');
  });
});
