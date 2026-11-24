/** 로그인 화면 위 여백 (Flutter LoginScreen: clamp(244/917 * 화면 높이, 64, 244)) */
export function loginTopOffset(screenHeight: number): number {
  return Math.max(64, Math.min(244, (screenHeight * 244) / 917));
}

/**
 * 위 여백. 시안 위치(top)까지만 쓰되, 내용이 안전 영역보다 길면 줄인다(최소 16).
 * 내용 높이를 아직 모르면(0) top 그대로.
 */
export function authTopSpacer({ top, safeHeight, contentHeight, bottom }: { top: number; safeHeight: number; contentHeight: number; bottom: number }): number {
  const max = Math.max(16, top);
  if (contentHeight <= 0) return max;
  return Math.min(max, Math.max(16, safeHeight - contentHeight - bottom));
}

/** 좌우 여백: 33 이지만 좁은 화면에선 폭의 8% (AuthScaffold) */
export function authHorizontalPadding(screenWidth: number, gutter: number): number {
  return Math.min(gutter, screenWidth * 0.08);
}
