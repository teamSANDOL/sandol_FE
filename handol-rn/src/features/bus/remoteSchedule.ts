import {
  ALL_DIRECTIONS,
  type ShuttleDayType,
  type ShuttleDirection,
  type ShuttleEntry,
  type ShuttleStops,
  type ShuttleTimetable,
} from './model';

/**
 * GET /static-info/bus/timetable?date= 응답(하루치)을 도메인 시간표로 바꾼 것
 * (Flutter remote_shuttle_schedule.dart). 서버가 그날의 day_type 과 방향별 구간을 확정해 준다.
 */
export interface RemoteSchedule {
  /** 응답이 가리키는 날짜 (YYYY-MM-DD, KST) */
  date: string;
  dayType: ShuttleDayType;
  /** 시간표 내용 해시. 날짜와 무관하다 (If-None-Match) */
  version: string;
  /** 최신 파싱이 검증에 실패해 직전 정상본을 내보내는 중인지 */
  needsReview: boolean;
  stops: ShuttleStops;
  entries: Partial<Record<ShuttleDirection, ShuttleEntry[]>>;
}

type Json = Record<string, unknown>;
const isRecord = (v: unknown): v is Json => typeof v === 'object' && v !== null && !Array.isArray(v);
const asList = (v: unknown): Json[] => {
  if (!Array.isArray(v) || !v.every(isRecord)) throw new TypeError('list expected');
  return v;
};
const optNumber = (v: unknown): number | null => (typeof v === 'number' ? v : null);
const optString = (v: unknown): string | null => (typeof v === 'string' ? v : null);

const DIRECTION_BY_ID: Record<string, ShuttleDirection> = {
  main_out: 'schoolToJeongwang',
  main_in: 'jeongwangToSchool',
  campus2_out: 'schoolToCampus2',
  campus2_in: 'campus2ToSchool',
  campus2_from_station: 'jeongwangToCampus2',
  campus2_to_station: 'campus2ToJeongwang',
};

const DAY_TYPES: readonly string[] = ['weekday', 'saturday', 'sunday', 'holiday'];

/** "HH:MM" → 자정 기준 분. 형식이 다르면 null */
function minutesOf(raw: unknown): number | null {
  if (typeof raw !== 'string') return null;
  const m = /^(\d{2}):(\d{2})$/.exec(raw);
  if (!m) return null;
  const h = Number(m[1]);
  const min = Number(m[2]);
  return h > 23 || min > 59 ? null : h * 60 + min;
}

/** 구간 → 시간표 항목. 도착버스 탑승의 승차 안내는 출발 정류장 boarding_note, 없으면 구간 note */
function entryOf(seg: Json, stopNote: string | null): ShuttleEntry | null {
  if (seg.type === 'fixed') {
    const t = minutesOf(seg.time);
    return t === null ? null : { type: 'fixed', start: t };
  }
  const start = minutesOf(seg.start);
  const end = minutesOf(seg.end);
  if (start === null || end === null) return null;
  if (seg.type === 'frequent') return { type: 'flexible', start, end };
  if (seg.type === 'arrival_board') {
    return { type: 'arrivalBoarding', start, end, boardingNote: stopNote ?? optString(seg.note) ?? '도착 버스 탑승' };
  }
  return null;
}

function parseStops(raw: unknown): ShuttleStops {
  const stops: ShuttleStops = {};
  for (const s of asList(raw)) {
    if (typeof s.id !== 'string' || typeof s.name !== 'string') throw new TypeError('stop');
    stops[s.id] = { name: s.name, lat: optNumber(s.lat), lng: optNumber(s.lng), boardingNote: optString(s.boarding_note) };
  }
  return stops;
}

function parseEntries(routes: unknown, stops: ShuttleStops): RemoteSchedule['entries'] | null {
  const entries: RemoteSchedule['entries'] = {};
  const seen = new Set<string>();
  for (const route of asList(routes)) {
    for (const d of asList(route.directions)) {
      const direction = typeof d.id === 'string' ? DIRECTION_BY_ID[d.id] : undefined;
      if (!direction) return null;
      seen.add(d.id as string);
      const stopNote = stops[String(d.from)]?.boardingNote ?? null;
      const list = (entries[direction] ??= []);
      for (const seg of asList(d.segments)) {
        const entry = entryOf(seg, stopNote);
        if (!entry) return null;
        list.push(entry);
      }
    }
  }
  return seen.size === ALL_DIRECTIONS.length ? entries : null;
}

/**
 * 응답 본문(파싱된 JSON)을 해석한다. 계약과 형식이 다르면(방향 6개 중 하나라도 없거나 모르는 구간 종류 ·
 * 시각 형식 포함) null. 일부만 쓰면 구간을 빠뜨린 시간표가 정시편처럼 보일 수 있어 통째로 버린다.
 */
export function parseRemoteSchedule(json: unknown): RemoteSchedule | null {
  try {
    if (!isRecord(json)) return null;
    const { date, version, day_type: dayType } = json;
    if (typeof date !== 'string' || typeof version !== 'string' || typeof dayType !== 'string') return null;
    if (!DAY_TYPES.includes(dayType)) return null;
    const stops = parseStops(json.stops);
    const entries = parseEntries(json.routes, stops);
    if (!entries) return null;
    const source = json.source;
    return {
      date,
      dayType: dayType as ShuttleDayType,
      version,
      needsReview: isRecord(source) && source.needs_review === true,
      stops,
      entries,
    };
  } catch {
    return null;
  }
}

/** 그날 운행이 없으면(segments: []) 미운행(null) */
export function remoteTimetable(schedule: RemoteSchedule, direction: ShuttleDirection): ShuttleTimetable | null {
  const entries = schedule.entries[direction];
  return entries && entries.length > 0 ? { direction, dayType: schedule.dayType, entries } : null;
}
