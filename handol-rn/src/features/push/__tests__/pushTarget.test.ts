import { isSchoolUrl, pushTargetFrom } from '../pushTarget';

describe('pushTargetFrom', () => {
  const notice = { type: 'notice', id: '1234', url: 'https://www.tukorea.ac.kr/a?b=1', title: '수강신청 안내', author: '학사팀', created_at: '2026-10-21' };

  it('공지 payload 는 공지 상세로 간다', () => {
    expect(pushTargetFrom(notice)).toEqual({
      href: { pathname: '/notice/detail', params: { id: '1234' } },
      notice: { id: 1234, url: notice.url, title: '수강신청 안내', author: '학사팀', createdAt: '2026-10-21' },
    });
  });

  it('학교 도메인이 아니거나 id·제목이 잘못된 공지는 버린다', () => {
    expect(pushTargetFrom({ ...notice, url: 'https://evil.com/tukorea.ac.kr' })).toBeNull();
    expect(pushTargetFrom({ ...notice, id: 'abc' })).toBeNull();
    expect(pushTargetFrom({ ...notice, id: '0' })).toBeNull();
    expect(pushTargetFrom({ ...notice, title: undefined })).toBeNull();
  });

  it('허용된 탭만 연다', () => {
    expect(pushTargetFrom({ route: '/bus' })).toEqual({ href: '/bus' });
    expect(pushTargetFrom({ route: '/user/withdraw' })).toBeNull();
    expect(pushTargetFrom(undefined)).toBeNull();
  });
});

describe('isSchoolUrl', () => {
  it.each([
    ['https://tukorea.ac.kr', true],
    ['https://www.tukorea.ac.kr/x', true],
    ['http://www.tukorea.ac.kr/x', false],
    ['https://tukorea.ac.kr.evil.com/', false],
    ['https://tukorea.ac.kr@evil.com/', false],
    ['https://nottukorea.ac.kr/', false],
  ])('%s → %s', (url, ok) => expect(isSchoolUrl(url)).toBe(ok));
});
