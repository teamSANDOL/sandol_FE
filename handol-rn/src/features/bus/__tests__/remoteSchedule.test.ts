import { parseRemoteSchedule, remoteTimetable } from '../remoteSchedule';
import { buildBoard } from '../board';

const direction = (id: string, from: string, segments: unknown[]) => ({ id, from, segments });

function body(overrides: Record<string, unknown> = {}, tweak?: (r: Record<string, unknown>[]) => void) {
  const routes = [
    {
      directions: [
        direction('main_in', 'jeongwang', [{ type: 'frequent', start: '08:40', end: '10:00' }, { type: 'fixed', time: '10:00' }]),
        direction('main_out', 'main_campus', [{ type: 'fixed', time: '09:00' }]),
      ],
    },
    {
      directions: [
        direction('campus2_out', 'main_campus', []),
        direction('campus2_in', 'campus2', [{ type: 'fixed', time: '09:40' }]),
        direction('campus2_from_station', 'jeongwang', [{ type: 'arrival_board', start: '17:00', end: '22:17' }]),
        direction('campus2_to_station', 'campus2', []),
      ],
    },
  ];
  tweak?.(routes as unknown as Record<string, unknown>[]);
  return {
    date: '2026-11-24',
    version: 'abc',
    day_type: 'weekday',
    stops: [
      { id: 'main_campus', name: '정문', lat: 37.3, lng: 126.7, boarding_note: '산융관 앞' },
      { id: 'jeongwang', name: '정왕역', lat: null, lng: null },
      { id: 'campus2', name: '제2캠퍼스' },
    ],
    routes,
    source: { needs_review: true },
    ...overrides,
  };
}

describe('parseRemoteSchedule', () => {
  it('정상 응답을 시간표로 바꾼다', () => {
    const r = parseRemoteSchedule(body());
    expect(r).not.toBeNull();
    expect(r?.needsReview).toBe(true);
    expect(r?.stops.main_campus).toMatchObject({ name: '정문', boardingNote: '산융관 앞' });
    expect(r?.stops.jeongwang.lat).toBeNull();
    const t = r && remoteTimetable(r, 'jeongwangToSchool');
    expect(t?.entries).toEqual([
      { type: 'flexible', start: 520, end: 600 },
      { type: 'fixed', start: 600 },
    ]);
  });
  it('도착버스 탑승의 승차 안내는 출발 정류장 boarding_note → 구간 note → 기본 문구', () => {
    const r = parseRemoteSchedule(body());
    expect(r && remoteTimetable(r, 'jeongwangToCampus2')?.entries[0].boardingNote).toBe('도착 버스 탑승');
    const withNote = parseRemoteSchedule(
      body({ stops: [{ id: 'jeongwang', name: '정왕역', boarding_note: '꽃집 앞' }, { id: 'main_campus', name: '정문' }, { id: 'campus2', name: '2' }] }),
    );
    expect(withNote && remoteTimetable(withNote, 'jeongwangToCampus2')?.entries[0].boardingNote).toBe('꽃집 앞');
  });
  it('segments 가 비면 미운행(null)', () => {
    const r = parseRemoteSchedule(body());
    expect(r && remoteTimetable(r, 'schoolToCampus2')).toBeNull();
  });
  it('방향 6개가 모두 없으면 통째로 버린다', () => {
    expect(parseRemoteSchedule(body({}, (routes) => (routes[1] as { directions: unknown[] }).directions.pop()))).toBeNull();
  });
  it('모르는 구간 종류 · 시각 형식은 통째로 버린다', () => {
    expect(parseRemoteSchedule(body({}, (r) => ((r[0] as { directions: { segments: unknown[] }[] }).directions[1].segments = [{ type: 'weird' }])))).toBeNull();
    expect(parseRemoteSchedule(body({}, (r) => ((r[0] as { directions: { segments: unknown[] }[] }).directions[1].segments = [{ type: 'fixed', time: '9:00' }])))).toBeNull();
    expect(parseRemoteSchedule(body({}, (r) => ((r[0] as { directions: { segments: unknown[] }[] }).directions[1].segments = [{ type: 'fixed', time: '24:00' }])))).toBeNull();
  });
  it('필드 타입이 계약과 다르면 null', () => {
    expect(parseRemoteSchedule(body({ routes: 'x' }))).toBeNull();
    expect(parseRemoteSchedule(body({ day_type: 'funday' }))).toBeNull();
    expect(parseRemoteSchedule(null)).toBeNull();
    expect(parseRemoteSchedule('text')).toBeNull();
  });
  it('서버 시간표가 있으면 내장 대신 쓴다', () => {
    const r = parseRemoteSchedule(body());
    const b = buildBoard(r, 'schoolToJeongwang', new Date(Date.UTC(2026, 10, 29, 8, 55))); // 일요일이지만 서버가 정한 시간표
    expect(b.next).toMatchObject({ status: 'upcoming', departureMinutes: 540 });
  });
});
