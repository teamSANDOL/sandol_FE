import { builtinTimetable, dayTypeOf } from './scheduleData';
import { calculateNextShuttle, upcomingEntries, withTransfer } from './nextShuttle';
import { reversedDirection, type NextShuttle, type ShuttleDirection, type ShuttleEntry, type ShuttleTimetable } from './model';
import { remoteTimetable, type RemoteSchedule } from './remoteSchedule';
import { computeConnections, legsOf, type ShuttleConnection } from './transfer';

/** 방향별 오늘 시간표. 서버 시간표가 있으면 그것을, 없으면 내장 시간표를 앱 공휴일 목록으로 고른다. now = KST 벽시계 Date */
export function timetableOf(schedule: RemoteSchedule | null, direction: ShuttleDirection, now: Date): ShuttleTimetable | null {
  return schedule ? remoteTimetable(schedule, direction) : builtinTimetable(direction, dayTypeOf(now));
}

export interface ShuttleBoard {
  timetable: ShuttleTimetable | null;
  /** 반대 방향 시간표 (시간표 화면 두 번째 카드) */
  reversedTimetable: ShuttleTimetable | null;
  next: NextShuttle;
  upcoming: ShuttleEntry[];
  /** 정왕역 ↔ 제2캠퍼스만. 본교를 거치지 않으면 null */
  transfers: ShuttleConnection[] | null;
}

/** 홈 카드와 셔틀 화면이 함께 쓰는 한 방향의 계산 결과 */
export function buildBoard(schedule: RemoteSchedule | null, direction: ShuttleDirection, now: Date): ShuttleBoard {
  const nowMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  const timetable = timetableOf(schedule, direction, now);
  const legs = legsOf(direction);
  const transfers = legs
    ? computeConnections(timetableOf(schedule, legs[0], now), timetableOf(schedule, legs[1], now), nowMinutes)
    : null;
  return {
    timetable,
    reversedTimetable: timetableOf(schedule, reversedDirection(direction), now),
    next: withTransfer(calculateNextShuttle(timetable, nowMinutes), transfers),
    upcoming: upcomingEntries(timetable, nowMinutes),
    transfers,
  };
}
