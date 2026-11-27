import { resolveAssetUrl } from '../assetUrl';

const B = 'https://bff.kr/';
describe('resolveAssetUrl', () => {
  it('https 는 그대로, BFF 경로·이름은 붙인다', () => {
    expect(resolveAssetUrl('https://cdn.kr/a.jpg', B)).toBe('https://cdn.kr/a.jpg');
    expect(resolveAssetUrl('/app/v1/assets/a.jpg', B)).toBe('https://bff.kr/app/v1/assets/a.jpg');
    expect(resolveAssetUrl('a.jpg', B)).toBe('https://bff.kr/app/v1/assets/a.jpg');
  });
  it('위험하거나 빈 값은 버린다', () => {
    for (const v of ['http://a.kr/x.png', '//evil.kr/x', 'javascript:alert(1)', 'data:image/png;base64,AA', '', null]) {
      expect(resolveAssetUrl(v, B)).toBeUndefined();
    }
  });
});
