import { buildUrl, resolveUrl } from '../client';

describe('buildUrl', () => {
  test('joins base and path and keeps trailing slash', () => {
    expect(buildUrl('https://sandori.kr', '/meal/restaurants/')).toBe('https://sandori.kr/meal/restaurants/');
    expect(buildUrl('https://sandori.kr/', 'meal/meals')).toBe('https://sandori.kr/meal/meals');
  });
  test('encodes query, repeats arrays, skips null', () => {
    expect(buildUrl('https://a.b', '/x', { q: '한 돌', ids: [1, 2], skip: null, page: 1 })).toBe(
      'https://a.b/x?q=%ED%95%9C%20%EB%8F%8C&ids=1&ids=2&page=1',
    );
  });
  test('absolute path ignores base', () => {
    expect(buildUrl('https://a.b', 'https://c.d/e', { k: 'v' })).toBe('https://c.d/e?k=v');
  });
});

describe('resolveUrl', () => {
  test('keeps absolute, resolves root-relative and relative', () => {
    expect(resolveUrl('https://x.y/a.png', 'https://sandori.kr')).toBe('https://x.y/a.png');
    expect(resolveUrl('/static/a.png', 'https://sandori.kr/meal')).toBe('https://sandori.kr/static/a.png');
    expect(resolveUrl('a.png', 'https://sandori.kr')).toBe('https://sandori.kr/a.png');
  });
});
