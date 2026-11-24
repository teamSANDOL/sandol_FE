import { isTabRoute, parseBannerLink } from '../model';
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
