import {
  COUNTDOWN_LIMIT_MINUTES,
  covers,
  isActive,
  isSegment,
  timeLabel,
  type NextShuttle,
  type ShuttleEntry,
  type ShuttleTimetable,
} from './model';
import type { ShuttleConnection } from './transfer';

/** 구간 항목의 이름 (수시운행 / 도착버스 탑승) */
export const segmentName = (e: ShuttleEntry): string => (e.type === 'flexible' ? '수시운행' : '도착버스 탑승');

function segmentStatus(e: ShuttleEntry): NextShuttle {
  if (e.type === 'flexible') {
    return {
      status: 'flexible',
      statusLabel: '수시운행',
      subText: e.end === undefined ? undefined : `${timeLabel(e.start)}~${timeLabel(e.end)} 수시운행`,
    };
  }
  const lastBus = e.end === undefined ? undefined : `막차 ${timeLabel(e.end)}`;
  return {
    status: 'arrivalBoarding',
    statusLabel: '도착버스 탑승',
    subText: [e.boardingNote, lastBus].filter((s): s is string => s !== undefined).join(' · '),
  };
}

/** 현재 시각(nowMinutes) 기준 다음 셔틀. 순수 함수 */
export function calculateNextShuttle(timetable: ShuttleTimetable | null, nowMinutes: number): NextShuttle {
  if (!timetable) return { status: 'notOperating', statusLabel: '운행 안함', subText: '오늘은 운행하지 않아요' };
  const entries = timetable.entries;

  // 1) 구간(수시운행 · 도착버스 탑승) 안이면 우선
  const inside = entries.find((e) => isSegment(e) && covers(e, nowMinutes));
  if (inside) return segmentStatus(inside);

  // 2) 시작 시각이 지금 이후인 가장 이른 항목. 아직 시작 전인 구간은 시작 시각까지의 대기로 안내한다.
  for (const e of entries) {
    if (e.start < nowMinutes) continue;
    if (isSegment(e) && e.start === nowMinutes) return segmentStatus(e);
    const remain = e.start - nowMinutes;
    const subText = isSegment(e)
      ? `${timeLabel(e.start)}부터 ${segmentName(e)}`
      : remain <= COUNTDOWN_LIMIT_MINUTES
        ? `${timeLabel(e.start)} 출발`
        : undefined; // 20분 밖이면 머리글이 이미 "HH:MM 출발"
    return { status: 'upcoming', remainMinutes: remain, departureMinutes: e.start, subText };
  }

  // 3) 남은 항목 없음 → 막차 종료
  return { status: 'closed', statusLabel: '운행 종료', subText: '오늘 운행이 종료되었어요' };
}

/** 아직 끝나지 않은 시간표 항목 최대 count 개 (진행 중 구간 포함) */
export function upcomingEntries(timetable: ShuttleTimetable | null, nowMinutes: number, count = 3): ShuttleEntry[] {
  if (!timetable) return [];
  return timetable.entries.filter((e) => e.start >= nowMinutes || covers(e, nowMinutes)).slice(0, count);
}

/**
 * 직행이 없거나 끝났어도 본교 환승(정왕역 ↔ 제2캠퍼스)이 있으면 가장 빠른 환승편을 안내한다.
 * transfers 는 본교를 거치지 않는 방향이면 null.
 */
export function withTransfer(direct: NextShuttle, transfers: readonly ShuttleConnection[] | null): NextShuttle {
  if (isActive(direct)) return direct;
  const c = transfers?.find((t) => !t.tight);
  if (!c) return direct;
  return {
    status: 'upcoming',
    // 남은 분이 없으니 머리글은 statusLabel 이고 강조색(운행 중)으로 보인다
    statusLabel: direct.status === 'notOperating' ? '직행 없음 · 환승 이용' : '직행 종료 · 환승 이용',
    subText: `${timeLabel(c.departure)} 출발 → 본교 ${timeLabel(c.transfer)} 환승`,
  };
}

/** 홈 카드 머리글. 카운트다운 구간(1~20분)이면 초까지, 아니면 headline 그대로 */
export function countdownText(departureMinutes: number, nowMinutes: number, nowSeconds: number): string {
  const seconds = (departureMinutes - nowMinutes) * 60 - nowSeconds;
  if (seconds <= 0) return '곧 출발';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m === 0) return `${s}초 뒤 출발`;
  return s === 0 ? `${m}분 뒤 출발` : `${m}분 ${s}초 뒤 출발`;
}

/** 카운트다운(매초 갱신) 구간인지 */
export function isCounting(n: NextShuttle): boolean {
  const r = n.remainMinutes;
  return n.status === 'upcoming' && n.departureMinutes !== undefined && r !== undefined && r > 0 && r <= COUNTDOWN_LIMIT_MINUTES;
}

/** "9:20" (시 앞 0 없음) */
export const shortClock = (minutes: number): string => `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, '0')}`;

/** "4시간 39분" / "12분" */
export function remainLabel(minutes: number): string {
  if (minutes < 60) return `${minutes}분`;
  const m = minutes % 60;
  return m === 0 ? `${Math.floor(minutes / 60)}시간` : `${Math.floor(minutes / 60)}시간 ${m}분`;
}
