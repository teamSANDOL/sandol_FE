import { BUILTIN_STOPS } from '../scheduleData';
import { nearestShuttleDirection } from '../nearestOrigin';

describe('nearestShuttleDirection', () => {
  it('학교 근처면 학교 → 정왕역', () => {
    expect(nearestShuttleDirection({ latitude: 37.3398, longitude: 126.7323 }, BUILTIN_STOPS)).toBe('schoolToJeongwang');
  });
  it('정왕역 근처면 정왕역 → 학교', () => {
    expect(nearestShuttleDirection({ latitude: 37.3513, longitude: 126.7412 }, BUILTIN_STOPS)).toBe('jeongwangToSchool');
  });
  it('제2캠퍼스 근처면 제2캠퍼스 → 본교', () => {
    expect(nearestShuttleDirection({ latitude: 37.3306, longitude: 126.6907 }, BUILTIN_STOPS)).toBe('campus2ToSchool');
  });
  it('좌표 없는 정류장은 판정에서 빠진다', () => {
    const stops = { ...BUILTIN_STOPS, campus2: { name: '제2캠퍼스', lat: null, lng: null } };
    expect(nearestShuttleDirection({ latitude: 37.3306, longitude: 126.6907 }, stops)).toBe('schoolToJeongwang');
  });
  it('좌표가 하나도 없으면 학교 출발', () => {
    expect(nearestShuttleDirection({ latitude: 0, longitude: 0 }, {})).toBe('schoolToJeongwang');
  });
});
