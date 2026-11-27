import { isTabRoute, parseBannerLink, parseServerBanner, parseServerBanners } from '../model';
import { splashTarget } from '../splashRoute';

describe('parseBannerLink', () => {
  it('https 는 외부 링크', () => {
    expect(parseBannerLink('https://instagram.com/x')).toEqual({ kind: 'external', url: 'https://instagram.com/x' });
  });
  it('허용 경로는 앱 링크(쿼리 포함)', () => {
    expect(parseBannerLink('/meal')).toEqual({ kind: 'app', location: '/meal' });
    expect(parseBannerLink('/home/organization?query=a')).toEqual({ kind: 'app', location: '/home/organization?query=a' });
  });
  it('http · 모르는 경로 · 빈 값은 undefined', () => {
    expect(parseBannerLink('http://a.com')).toBeUndefined();
    expect(parseBannerLink('/secret')).toBeUndefined();
    expect(parseBannerLink('//evil.com')).toBeUndefined();
    expect(parseBannerLink('  ')).toBeUndefined();
    expect(parseBannerLink(null)).toBeUndefined();
  });
});

describe('isTabRoute', () => {
  it('탭 루트만 true', () => {
    expect(isTabRoute('/bus')).toBe(true);
    expect(isTabRoute('/home/organization')).toBe(false);
  });
});

describe('splashTarget', () => {
  it('복원 중이면 대기', () => expect(splashTarget('restoring', true)).toBeNull());
  it('로그인 또는 둘러보기 유효면 홈', () => {
    expect(splashTarget('signedIn', false)).toBe('/home');
    expect(splashTarget('signedOut', true)).toBe('/home');
  });
  it('그 외 로그인', () => expect(splashTarget('signedOut', false)).toBe('/login'));
});

describe('parseServerBanner', () => {
  const B = 'https://bff.kr';
  const now = Date.parse('2026-11-27T12:00:00+09:00');
  it('그림 배너는 https 그림 한 장', () => {
    expect(parseServerBanner({ id: 'a', kind: 'image', title: '축제', image_url: 'https://cdn/x.jpg', link: 'https://insta.com/x' }, B, now)).toEqual({
      id: 'a', title: '축제', imageUrl: 'https://cdn/x.jpg', link: { kind: 'external', url: 'https://insta.com/x' },
    });
    expect(parseServerBanner({ id: 'a', kind: 'image', title: '축제', image_url: 'http://cdn/x.jpg' }, B, now)).toBeUndefined();
    expect(parseServerBanner({ id: 'a', kind: 'image', title: '축제', image_url: '/app/v1/assets/f.jpg' }, B, now)).toMatchObject({ imageUrl: 'https://bff.kr/app/v1/assets/f.jpg' });
  });
  it('글자 배너 아이콘은 링크 화면을 따른다', () => {
    expect(parseServerBanner({ id: 'b', kind: 'text', title: '셔틀', body: '시간표', link: '/bus' }, B, now)).toMatchObject({ icon: 'navBus', body: '시간표' });
  });
  it('기간 밖 · 모르는 kind · 필수값 없음은 버린다', () => {
    expect(parseServerBanner({ id: 'c', kind: 'text', title: 'x', ends_at: '2026-11-26T00:00:00+09:00' }, B, now)).toBeUndefined();
    expect(parseServerBanner({ id: 'c', kind: 'text', title: 'x', starts_at: '2026-12-01T00:00:00+09:00' }, B, now)).toBeUndefined();
    expect(parseServerBanner({ id: 'c', kind: 'video', title: 'x' }, B, now)).toBeUndefined();
    expect(parseServerBanners([{ kind: 'text', title: 'x' }, { id: 'd', kind: 'text', title: 'y' }], B, now)).toHaveLength(1);
  });
});
