/** 셔틀 도메인 모델 (Flutter bus/domain/model/shuttle_schedule.dart). 시각은 자정부터의 분(minute-of-day)으로 다룬다. */

export type StopId = 'main_campus' | 'jeongwang' | 'campus2';
export const STOP_IDS: readonly StopId[] = ['main_campus', 'jeongwang', 'campus2'];

/** 운행 방향. 서버 방향 id 6개와 1:1 이며 (출발, 도착) 정류장 조합이 정확히 이 여섯이다. */
export type ShuttleDirection =
  | 'jeongwangToSchool' // main_in
  | 'schoolToJeongwang' // main_out
  | 'schoolToCampus2' // campus2_out
  | 'campus2ToSchool' // campus2_in
  | 'jeongwangToCampus2' // campus2_from_station
  | 'campus2ToJeongwang'; // campus2_to_station

export const DIRECTIONS: Record<ShuttleDirection, { origin: StopId; destination: StopId }> = {
  jeongwangToSchool: { origin: 'jeongwang', destination: 'main_campus' },
  schoolToJeongwang: { origin: 'main_campus', destination: 'jeongwang' },
  schoolToCampus2: { origin: 'main_campus', destination: 'campus2' },
  campus2ToSchool: { origin: 'campus2', destination: 'main_campus' },
  jeongwangToCampus2: { origin: 'jeongwang', destination: 'campus2' },
  campus2ToJeongwang: { origin: 'campus2', destination: 'jeongwang' },
};

export const ALL_DIRECTIONS = Object.keys(DIRECTIONS) as ShuttleDirection[];

/** origin 에서 destination 으로 가는 방향. 같은 정류장이면 null */
export function directionBetween(origin: StopId, destination: StopId): ShuttleDirection | null {
  return ALL_DIRECTIONS.find((d) => DIRECTIONS[d].origin === origin && DIRECTIONS[d].destination === destination) ?? null;
}

/** 출발 · 도착을 맞바꾼 방향 */
export function reversedDirection(d: ShuttleDirection): ShuttleDirection {
  const { origin, destination } = DIRECTIONS[d];
  return directionBetween(destination, origin) as ShuttleDirection;
}

/** 정왕역 ↔ 제2캠퍼스 편은 본교를 거친다 */
export function viaSchool(d: ShuttleDirection): boolean {
  return d === 'jeongwangToCampus2' || d === 'campus2ToJeongwang';
}

/** 노선1: 정왕역 ↔ 본교(평일 전용) / 노선2: 제2캠퍼스 */
export type ShuttleRoute = 'route1' | 'route2';
export function routeOf(d: ShuttleDirection): ShuttleRoute {
  return d === 'jeongwangToSchool' || d === 'schoolToJeongwang' ? 'route1' : 'route2';
}

export type ShuttleDayType = 'weekday' | 'saturday' | 'sunday' | 'holiday';

export interface ShuttleStop {
  name: string;
  /** 좌표를 모르면 null — 가까운 출발지 판정에서 빠진다 */
  lat?: number | null;
  lng?: number | null;
  boardingNote?: string | null;
}
export type ShuttleStops = Record<string, ShuttleStop>;

export type ShuttleEntryType = 'fixed' | 'flexible' | 'arrivalBoarding';

/** 시간표 한 항목. fixed: start=출발 / flexible · arrivalBoarding: start~end 구간 */
export interface ShuttleEntry {
  type: ShuttleEntryType;
  start: number;
  end?: number;
  boardingNote?: string;
}

export const isSegment = (e: ShuttleEntry): boolean => e.type !== 'fixed';

/** now 가 구간 안인지. 끝 시각은 포함하지 않는다(반열린구간) */
export function covers(e: ShuttleEntry, nowMinutes: number): boolean {
  return e.end !== undefined && nowMinutes >= e.start && nowMinutes < e.end;
}

export interface ShuttleTimetable {
  direction: ShuttleDirection;
  dayType: ShuttleDayType;
  /** 시작 시각 오름차순 */
  entries: readonly ShuttleEntry[];
}

export type ShuttleStatus = 'upcoming' | 'flexible' | 'arrivalBoarding' | 'closed' | 'notOperating';

export interface NextShuttle {
  status: ShuttleStatus;
  remainMinutes?: number;
  departureMinutes?: number;
  statusLabel?: string;
  subText?: string;
}

/** 이보다 먼 출발은 분 숫자 대신 출발 시각을 보여준다 */
export const COUNTDOWN_LIMIT_MINUTES = 20;

/** "HH:MM" */
export function timeLabel(minutes: number): string {
  const h = String(Math.floor(minutes / 60)).padStart(2, '0');
  const m = String(minutes % 60).padStart(2, '0');
  return `${h}:${m}`;
}

/** 운행 종료 · 미운행은 강조색 대신 비활성 색으로 보인다 */
export function isActive(n: NextShuttle): boolean {
  return n.status !== 'closed' && n.status !== 'notOperating';
}

/** 카드 머리글 한 줄. 홈 카드와 셔틀 화면이 같은 문구를 쓴다 */
export function headline(n: NextShuttle): string {
  const { remainMinutes: remain, departureMinutes: time } = n;
  if (n.status === 'upcoming' && remain !== undefined) {
    if (remain <= 0) return '곧 출발';
    if (remain <= COUNTDOWN_LIMIT_MINUTES) return `${remain}분 뒤 출발`;
    if (time !== undefined) return `${timeLabel(time)} 출발`;
  }
  return n.statusLabel ?? '운행 정보 없음';
}
