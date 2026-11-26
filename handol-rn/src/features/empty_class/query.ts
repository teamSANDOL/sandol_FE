import { koreaNow, kstParts } from '@/core/utils/koreaTime';
import { classPeriods } from './periods';

/**
 * 빈 강의실 조회 조건: 날짜(오늘부터 daysAhead 일 뒤) + 시각 구간(0시 기준 분, 양끝 포함).
 * 백엔드는 요일만 받으므로 날짜는 요일로 보낸다. 오늘이면 축이 "지금"에서, 다른 날이면
 * 1교시 시작에서 시작한다. anchorMinutes 는 상태를 만들 때 한 번만 읽어 둔 "지금"이다.
 */
export interface ClassroomQuery {
  /** 1=월 … 7=일 */
  weekday: number;
  daysAhead: number;
  anchorMinutes: number;
  startMinutes: number;
  endMinutes: number;
}

/** 시계 값 (KST). minutes 는 0시 기준 분 */
export interface Clock {
  weekday: number;
  minutes: number;
}

export const DEFAULT_SPAN = 120;
export const HARD_END = 23 * 60 + 50;
export const MAX_DAYS_AHEAD = 6;
/** 앵커가 이만큼 오래되면 다시 맞춘다 */
export const STALE_AFTER = 10;
export const LAST_TICK = classPeriods[classPeriods.length - 1].end;
export const DAY_START = classPeriods[0].start;

const DAY_NAMES = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
const MS_PER_DAY = 24 * 60 * 60 * 1000;

const mod7 = (n: number): number => ((n % 7) + 7) % 7;

export function clockOf(d: Date = koreaNow()): Clock {
  const p = kstParts(d);
  return { weekday: p.weekday, minutes: p.hour * 60 + p.minute };
}

export function minutesOf(rawMinutes: number): number {
  return Math.min(Math.max(rawMinutes, 0), HARD_END - STALE_AFTER);
}

/**
 * 축의 디텐트: [지금, 이후의 교시 시작·끝 시각…, 22:30]. 밤늦게 칸이 없으면 30분 뒤(최대 23:50)를
 * 하나 붙여 최소 한 칸은 만든다.
 */
export function ticksFor(anchor: number): number[] {
  const set = new Set<number>([anchor]);
  for (const p of classPeriods) {
    set.add(p.start);
    set.add(p.end);
  }
  const ticks = [...set].filter((t) => t >= anchor).sort((a, b) => a - b);
  if (ticks.length < 2) ticks.push(Math.min(Math.max(anchor + 30, anchor + 1), HARD_END));
  return ticks;
}

/** minutes 에 가장 가까운 디텐트의 인덱스 */
export function nearestTickIndex(ticks: readonly number[], minutes: number): number {
  let best = 0;
  for (let i = 1; i < ticks.length; i++) {
    if (Math.abs(ticks[i] - minutes) < Math.abs(ticks[best] - minutes)) best = i;
  }
  return best;
}

/** 오늘 고를 교시가 남아 있는가. 마지막 교시(21:40)가 시작하면 오늘은 고를 수 없다. */
export function todaySelectable(rawMinutes: number): boolean {
  return minutesOf(rawMinutes) < classPeriods[classPeriods.length - 1].start;
}

/** clock 기준 daysAhead 일 뒤의 기본 구간 (지금부터 2시간에 가장 가까운 칸까지) */
export function forDay(clock: Clock, daysAhead: number): ClassroomQuery {
  const anchor = daysAhead === 0 ? minutesOf(clock.minutes) : DAY_START;
  const ticks = ticksFor(anchor);
  let endIdx = nearestTickIndex(ticks, anchor + DEFAULT_SPAN);
  if (endIdx === 0) endIdx = 1;
  return {
    weekday: mod7(clock.weekday - 1 + daysAhead) + 1,
    daysAhead,
    anchorMinutes: anchor,
    startMinutes: anchor,
    endMinutes: ticks[endIdx],
  };
}

/** 오늘 고를 교시가 없으면 내일로 넘긴다 */
export function defaultFor(clock: Clock): ClassroomQuery {
  return forDay(clock, todaySelectable(clock.minutes) ? 0 : 1);
}

export function setRange(q: ClassroomQuery, startMinutes: number, endMinutes: number): ClassroomQuery {
  if (startMinutes >= endMinutes) return q;
  if (startMinutes === q.startMinutes && endMinutes === q.endMinutes) return q;
  return { ...q, startMinutes, endMinutes };
}

/** 축의 디텐트 인덱스로 구간을 고른다 */
export function setRangeByTick(q: ClassroomQuery, startIndex: number, endIndex: number): ClassroomQuery {
  const ticks = ticksFor(q.anchorMinutes);
  const s = Math.min(Math.max(startIndex, 0), ticks.length - 2);
  const e = Math.min(Math.max(endIndex, s + 1), ticks.length - 1);
  return setRange(q, ticks[s], ticks[e]);
}

/** 날짜를 바꾼다. 고른 구간을 새 축의 가까운 칸에 맞춰 유지하고, 사라지면 그날의 기본 구간으로 */
export function setDay(q: ClassroomQuery, clock: Clock, daysAhead: number): ClassroomQuery {
  if (daysAhead === q.daysAhead) return q;
  const next = forDay(clock, daysAhead);
  const ticks = ticksFor(next.anchorMinutes);
  const s = ticks[nearestTickIndex(ticks, q.startMinutes)];
  const e = ticks[nearestTickIndex(ticks, q.endMinutes)];
  return s < e ? { ...next, startMinutes: s, endMinutes: e } : next;
}

/** 화면에 들어올 때 한 번. 앵커가 10분 이상 오래됐을 때만 축을 다시 맞춘다. */
export function syncToNow(q: ClassroomQuery, clock: Clock): ClassroomQuery {
  // 자정을 넘겨 '오늘'이 바뀌었으면 처음부터
  if (mod7(q.weekday - 1 - q.daysAhead) + 1 !== clock.weekday) return defaultFor(clock);
  if (q.daysAhead !== 0) return q;
  const anchor = minutesOf(clock.minutes);
  if (anchor - q.anchorMinutes < STALE_AFTER) return q;
  if (!todaySelectable(clock.minutes)) return defaultFor(clock);

  const ticks = ticksFor(anchor);
  const keepsNow = q.startMinutes === q.anchorMinutes;
  const s = keepsNow ? anchor : ticks[nearestTickIndex(ticks, q.startMinutes)];
  const e = ticks[nearestTickIndex(ticks, q.endMinutes)];
  if (s >= e) return defaultFor(clock);
  return { weekday: clock.weekday, daysAhead: 0, anchorMinutes: anchor, startMinutes: s, endMinutes: e };
}

export function formatMinutes(minutes: number): string {
  const h = String(Math.floor(minutes / 60)).padStart(2, '0');
  const m = String(minutes % 60).padStart(2, '0');
  return `${h}:${m}`;
}

/** `09시`, `22시 30분` */
export function hourLabel(minutes: number): string {
  const h = `${String(Math.floor(minutes / 60)).padStart(2, '0')}시`;
  return minutes % 60 === 0 ? h : `${h} ${minutes % 60}분`;
}

export const dayName = (q: ClassroomQuery): string => DAY_NAMES[q.weekday - 1];
export const dayShort = (q: ClassroomQuery): string => dayName(q).slice(0, 1);
export const timeLabel = (q: ClassroomQuery): string => `${formatMinutes(q.startMinutes)} ~ ${formatMinutes(q.endMinutes)}`;
export const isToday = (q: ClassroomQuery): boolean => q.daysAhead === 0;
export const isWeekend = (q: ClassroomQuery): boolean => q.weekday >= 6;
/** 오늘 수업이 모두 끝난 뒤인가 (22:30 이후) */
export const isAfterClassDay = (q: ClassroomQuery): boolean => isToday(q) && q.anchorMinutes >= LAST_TICK;

export interface DayChip {
  daysAhead: number;
  /** 오늘 · 내일 · 요일 한 글자 */
  top: string;
  date: number;
  month: number;
  weekday: number;
  enabled: boolean;
}

const SHORT_DAYS = ['월', '화', '수', '목', '금', '토', '일'];
export const shortWeekday = (weekday: number): string => SHORT_DAYS[weekday - 1];

/** 오늘부터 일주일 날짜 칸. 마지막 교시 시작(21:40)이 지나면 오늘은 고를 수 없다. */
export function dayChips(now: Date = koreaNow()): DayChip[] {
  const todayOk = todaySelectable(clockOf(now).minutes);
  return Array.from({ length: MAX_DAYS_AHEAD + 1 }, (_, d) => {
    const p = kstParts(new Date(now.getTime() + d * MS_PER_DAY));
    const top = d === 0 ? '오늘' : d === 1 ? '내일' : shortWeekday(p.weekday);
    return { daysAhead: d, top, date: p.day, month: p.month, weekday: p.weekday, enabled: d > 0 || todayOk };
  });
}
