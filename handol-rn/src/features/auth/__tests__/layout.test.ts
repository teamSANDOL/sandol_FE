import { authHorizontalPadding, authTopSpacer, loginTopOffset } from '../layout';

describe('authTopSpacer', () => {
  it('내용이 짧으면 시안 위치', () => expect(authTopSpacer({ top: 200, safeHeight: 800, contentHeight: 300, bottom: 32 })).toBe(200));
  it('내용이 길면 줄이되 최소 16', () => {
    expect(authTopSpacer({ top: 200, safeHeight: 800, contentHeight: 700, bottom: 32 })).toBe(68);
    expect(authTopSpacer({ top: 200, safeHeight: 800, contentHeight: 790, bottom: 32 })).toBe(16);
  });
  it('높이 미측정이면 top', () => expect(authTopSpacer({ top: 200, safeHeight: 800, contentHeight: 0, bottom: 32 })).toBe(200));
});

describe('loginTopOffset', () => {
  it('917 높이에서 244', () => expect(loginTopOffset(917)).toBeCloseTo(244));
  it('작은 화면은 64, 큰 화면은 244 로 고정', () => {
    expect(loginTopOffset(100)).toBe(64);
    expect(loginTopOffset(3000)).toBe(244);
  });
});

describe('authHorizontalPadding', () => {
  it('넓으면 33, 좁으면 폭의 8% (412 폭은 32.96)', () => {
    expect(authHorizontalPadding(412, 33)).toBeCloseTo(32.96);
    expect(authHorizontalPadding(600, 33)).toBe(33);
    expect(authHorizontalPadding(300, 33)).toBeCloseTo(24);
  });
});
