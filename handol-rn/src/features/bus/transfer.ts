import { covers, isSegment, type ShuttleDirection, type ShuttleEntry, type ShuttleTimetable } from './model';

/** 본교 환승 연결 하나. first=1구간 항목, departure=1구간 탑승 시각, transfer=본교 2구간 출발 시각(분), tight=빠듯한 연결 */
export interface ShuttleConnection {
  first: ShuttleEntry;
  departure: number;
  transfer: number;
  tight: boolean;
}

/**
 * 1구간 출발 → 2구간 출발 최소 간격(분). 이동과 환승을 합친 안전 여유로 양방향 공통이다.
 * ponytail: 사용자가 정한 값. 서버가 구간 소요시간을 주면 방향별로 바꾼다.
 */
export const SAFE_GAP_MINUTES = 20;
/** "빠듯함"으로라도 보여 줄 최소 간격(분). 정왕역↔본교 소요시간(시간표 각주 10분) */
export const TIGHT_GAP_MINUTES = 10;

/** 정왕역 ↔ 제2캠퍼스 방향의 1구간 · 2구간 방향. 본교를 거치지 않으면 null */
export function legsOf(direction: ShuttleDirection): [ShuttleDirection, ShuttleDirection] | null {
  if (direction === 'jeongwangToCampus2') return ['jeongwangToSchool', 'schoolToCampus2'];
  if (direction === 'campus2ToJeongwang') return ['campus2ToSchool', 'schoolToJeongwang'];
  return null;
}

/** minutes 이후 t 에서 탈 수 있는 가장 이른 시각(분). 구간 안이면 그 시각 바로. 없으면 null */
function firstDeparture(t: ShuttleTimetable, minutes: number): number | null {
  let best: number | null = null;
  for (const e of t.entries) {
    let candidate: number;
    if (covers(e, minutes)) candidate = minutes;
    else if (e.start >= minutes) candidate = e.start;
    else continue;
    if (best === null || candidate < best) best = candidate;
  }
  return best;
}

/** 1구간 항목을 지금 이후 언제 탈 수 있는지. 이미 지났으면 null */
function departOf(e: ShuttleEntry, nowMinutes: number): number | null {
  if (isSegment(e) && e.end !== undefined) {
    if (e.end <= nowMinutes) return null;
    return Math.max(e.start, nowMinutes);
  }
  return e.start < nowMinutes ? null : e.start;
}

/**
 * now 이후 1구간 first 로 출발해 SAFE_GAP 뒤 이후의 첫 2구간 second 로 갈아타는 연결을 환승 시각순으로 최대 count 개.
 * 1구간 수시운행 · 도착버스 구간은 구간 안 아무 때나 탄다고 보고 지금(또는 구간 시작) 탄다고 계산한다.
 * 같은 2구간 편으로 이어지는 1구간이 여럿이면 가장 늦게 출발하는 것을 남긴다. 빠듯한 연결(tight)도 출발 시각순으로 섞인다.
 */
export function computeConnections(
  first: ShuttleTimetable | null,
  second: ShuttleTimetable | null,
  nowMinutes: number,
  count = 3,
): ShuttleConnection[] {
  if (!first || !second) return [];
  const byTransfer = new Map<number, { entry: ShuttleEntry; depart: number }>();
  for (const entry of first.entries) {
    const depart = departOf(entry, nowMinutes);
    if (depart === null) continue;
    const transfer = firstDeparture(second, depart + SAFE_GAP_MINUTES);
    if (transfer !== null) byTransfer.set(transfer, { entry, depart });
  }
  const keys = [...byTransfer.keys()].sort((a, b) => a - b);
  const safe: ShuttleConnection[] = keys.slice(0, count).map((transfer) => {
    const { entry, depart } = byTransfer.get(transfer) as { entry: ShuttleEntry; depart: number };
    return { first: entry, departure: depart, transfer, tight: false };
  });

  // 빠듯한 연결: 지금 이후 1구간 정시편 중 간격이 TIGHT 이상 SAFE 미만인 것. 안전 목록이 덮는 시각까지만(없으면 앞에서 count 개)
  const lastSafe = safe.length === 0 ? null : safe[safe.length - 1].transfer;
  const tight: ShuttleConnection[] = [];
  for (const e of first.entries) {
    if (isSegment(e) || e.start < nowMinutes) continue;
    const transfer = firstDeparture(second, e.start + TIGHT_GAP_MINUTES);
    if (transfer === null || transfer - e.start >= SAFE_GAP_MINUTES) continue;
    if (lastSafe !== null && transfer > lastSafe) continue;
    tight.push({ first: e, departure: e.start, transfer, tight: true });
  }
  return [...safe, ...(lastSafe === null ? tight.slice(0, count) : tight)].sort(
    (a, b) => a.departure - b.departure || a.transfer - b.transfer,
  );
}
