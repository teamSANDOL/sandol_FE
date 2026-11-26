import { displayId, expiryFromJwt, isAccessTokenValid, isRefreshTokenValid, usernameFromJwt } from '../session';

function jwt(payload: object): string {
  const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  return `${b64({ alg: 'none' })}.${b64(payload)}.sig`;
}

describe('AuthSession helpers', () => {
  test('displayId uses email local part, then username, then 사용자', () => {
    expect(displayId({ accessToken: 'a', email: 'kim@tukorea.ac.kr' })).toBe('kim');
    expect(displayId({ accessToken: 'a', username: 'lee@x.com' })).toBe('lee');
    expect(displayId({ accessToken: 'a' })).toBe('사용자');
  });

  test('access token validity honours 30s leeway', () => {
    const now = 1_000_000;
    expect(isAccessTokenValid({ accessToken: 'a', accessTokenExpiresAt: now + 31_000 }, now)).toBe(true);
    expect(isAccessTokenValid({ accessToken: 'a', accessTokenExpiresAt: now + 29_000 }, now)).toBe(false);
    expect(isAccessTokenValid({ accessToken: 'a' }, now)).toBe(true);
  });

  test('refresh token without expiry is valid, missing token is not', () => {
    expect(isRefreshTokenValid({ accessToken: 'a', refreshToken: 'r' })).toBe(true);
    expect(isRefreshTokenValid({ accessToken: 'a' })).toBe(false);
  });

  test('parses exp and preferred_username from JWT, ignores exp 0', () => {
    expect(expiryFromJwt(jwt({ exp: 100 }))).toBe(100_000);
    expect(expiryFromJwt(jwt({ exp: 0 }))).toBeNull();
    expect(expiryFromJwt('garbage')).toBeNull();
    expect(usernameFromJwt(jwt({ preferred_username: '한돌' }))).toBe('한돌');
  });
});
