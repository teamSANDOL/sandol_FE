import { isHoliday } from './holidays';
import {
  routeOf,
  type ShuttleDayType,
  type ShuttleDirection,
  type ShuttleEntry,
  type ShuttleStops,
  type ShuttleTimetable,
} from './model';

/**
 * 내장 시간표 (Flutter shuttle_schedule_data.dart). 서버도 기기 캐시도 못 쓸 때의 대체 경로다.
 * 2026-2학기(9.1 ~ 12.22) 학교 공지 이미지 기준. 학기마다 수동 갱신 필요.
 * - 노선1(정왕역↔본교): 평일 전용 / 노선2(제2캠퍼스): 평일 · 토요일, 일 · 공휴일 미운행
 */

/** 서버 stops 를 못 받을 때 쓰는 정류장. 키는 서버 정류장 id */
export const BUILTIN_STOPS: ShuttleStops = {
  main_campus: { name: '한국공학대 정문', lat: 37.3397375, lng: 126.7322656 },
  jeongwang: { name: '정왕역', lat: 37.3512712, lng: 126.7411157 },
  campus2: { name: '제2캠퍼스', lat: 37.3306875, lng: 126.6906875 },
};

const ARRIVAL_BOARDING_NOTE = '파리바게뜨 건너편 하차장소(버스정류장)에서 도착 버스 탑승';

const mins = (hhmm: number): number => Math.floor(hhmm / 100) * 60 + (hhmm % 100);
const fixed = (list: number[]): ShuttleEntry[] => list.map((t) => ({ type: 'fixed', start: mins(t) }));
const flexible = (s: number, e: number): ShuttleEntry => ({ type: 'flexible', start: mins(s), end: mins(e) });

// 노선1: 정왕역 → 학교 (평일). 08:40~10:00 수시 → 정시 → 17:00 이후 도착버스 탑승(막차 약 22:17)
const ROUTE1_UP_WEEKDAY: ShuttleEntry[] = [
  flexible(840, 1000),
  ...fixed([
    1000, 1010, 1015, 1020, 1030, 1050, 1100, 1110, 1120, 1130, 1150, 1200, 1210, 1220, 1230, 1250, 1300, 1310, 1320, 1330,
    1350, 1400, 1410, 1420, 1440, 1500, 1510, 1520, 1540, 1600, 1620, 1630, 1640, 1650,
  ]),
  { type: 'arrivalBoarding', start: mins(1700), end: mins(2217), boardingNote: ARRIVAL_BOARDING_NOTE },
];

// 노선1: 학교 → 정왕역 (평일). 09:00~16:50 정시 → 17:00~18:00 수시 → 18:00~22:40 정시
const ROUTE1_DOWN_WEEKDAY: ShuttleEntry[] = [
  ...fixed([
    900, 920, 940, 1000, 1005, 1010, 1020, 1040, 1050, 1100, 1110, 1120, 1140, 1150, 1200, 1210, 1220, 1240, 1250, 1300,
    1310, 1320, 1340, 1350, 1400, 1410, 1430, 1450, 1500, 1510, 1530, 1550, 1610, 1620, 1630, 1640, 1650,
  ]),
  flexible(1700, 1800),
  ...fixed([1800, 1810, 1820, 1830, 1840, 1850, 1905, 1915, 1930, 1945, 2005, 2025, 2045, 2100, 2120, 2148, 2210, 2240]),
];

const ROUTE2_TO_CAMPUS_WEEKDAY = fixed([1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900]);
const ROUTE2_FROM_STATION_WEEKDAY = fixed([855, 900]); // 평일 첫 2회는 정왕역 출발
const ROUTE2_FROM_STATION_SATURDAY = fixed([845, 850, 900, 905, 910, 915]);
const ROUTE2_FROM_CAMPUS_WEEKDAY = fixed([940, 1030, 1130, 1230, 1330, 1430, 1530, 1630, 1740, 1830, 1930]); // 17:40 편은 오이도역 경유
const ROUTE2_TO_STATION_SATURDAY = fixed([1630, 1645, 1925, 1928, 1930, 1935, 1945]);

/**
 * KST 벽시계 Date → 요일 구분. 서버 day_type 을 못 받을 때만 쓴다.
 * 공휴일(대체공휴일 포함)이면 holiday, 목록 밖 연도는 요일만으로 판정한다.
 */
export function dayTypeOf(d: Date): ShuttleDayType {
  if (isHoliday(d)) return 'holiday';
  const dow = d.getUTCDay();
  if (dow === 6) return 'saturday';
  if (dow === 0) return 'sunday';
  return 'weekday';
}

function entriesFor(direction: ShuttleDirection, dayType: ShuttleDayType): ShuttleEntry[] | null {
  if (routeOf(direction) === 'route1') {
    if (dayType !== 'weekday') return null;
    return direction === 'jeongwangToSchool' ? ROUTE1_UP_WEEKDAY : ROUTE1_DOWN_WEEKDAY;
  }
  if (dayType === 'sunday' || dayType === 'holiday') return null;
  const saturday = dayType === 'saturday';
  switch (direction) {
    case 'schoolToCampus2':
      return saturday ? null : ROUTE2_TO_CAMPUS_WEEKDAY;
    case 'campus2ToSchool':
      return saturday ? null : ROUTE2_FROM_CAMPUS_WEEKDAY;
    case 'jeongwangToCampus2':
      return saturday ? ROUTE2_FROM_STATION_SATURDAY : ROUTE2_FROM_STATION_WEEKDAY;
    case 'campus2ToJeongwang':
      return saturday ? ROUTE2_TO_STATION_SATURDAY : null;
    default:
      return null;
  }
}

/** (방향 · 요일)에 해당하는 내장 시간표. 미운행이면 null */
export function builtinTimetable(direction: ShuttleDirection, dayType: ShuttleDayType): ShuttleTimetable | null {
  const entries = entriesFor(direction, dayType);
  return entries ? { direction, dayType, entries } : null;
}
