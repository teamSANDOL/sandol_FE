import { isNewerVersion, parseVersion } from '../version';

describe('version', () => {
  test('태그 형식을 읽는다', () => {
    expect(parseVersion('v0.3.23')).toEqual([0, 3, 23]);
    expect(parseVersion('0.4')).toEqual([0, 4]);
    expect(parseVersion('v0.3.23-beta')).toBeNull();
    expect(parseVersion('../x')).toBeNull();
  });

  test('새 버전만 true', () => {
    expect(isNewerVersion('v0.3.24', '0.3.23')).toBe(true);
    expect(isNewerVersion('v0.4.0', '0.3.99')).toBe(true);
    expect(isNewerVersion('v0.3.23', '0.3.23')).toBe(false);
    expect(isNewerVersion('v0.3.9', '0.3.23')).toBe(false);
    expect(isNewerVersion('v1', '0.9.9')).toBe(true);
    expect(isNewerVersion('garbage', '0.3.23')).toBe(false);
  });
});
