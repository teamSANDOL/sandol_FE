import { breakAnywhere, routeTitle } from '../timetableView';
import { BUILTIN_STOPS } from '../scheduleData';

describe('timetableView', () => {
  it('breakAnywhere 는 글자 사이에만 U+200B 를 넣고 원문은 그대로 복원된다', () => {
    const s = '본교 출발은 정류장.';
    const out = breakAnywhere(s);
    expect(out.replace(/\u200B/g, '')).toBe(s);
    expect(out).toContain('본\u200B교 ');
    expect(out.endsWith('.')).toBe(true);
  });
  it('routeTitle 은 본교 경유를 붙인다', () => {
    expect(routeTitle('jeongwangToCampus2', BUILTIN_STOPS)).toBe('정왕역 → 제2캠퍼스 (한국공학대 정문 경유)');
    expect(routeTitle('schoolToJeongwang', BUILTIN_STOPS)).toBe('한국공학대 정문 → 정왕역');
  });
});
