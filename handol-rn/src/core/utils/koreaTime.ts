const OFFSET_MS = 9 * 60 * 60 * 1000;

/** 테스트가 고정 시각을 넣을 때만 바꾼다 */
export const clock = { now: (): number => Date.now() };

/**
 * 한국 표준시(KST) 벽시계 값. 반환 Date 의 getUTC* 가 한국 시각이다.
 * (기기 시간대와 무관하게 셔틀 · 식단 · 빈 강의실 판단에 쓴다)
 */
export function koreaNow(): Date {
  return new Date(clock.now() + OFFSET_MS);
}

/** KST 벽시계 Date 에서 필드 읽기 (getUTC* 래퍼). weekday: 1=월 … 7=일 (Dart 와 같음) */
export function kstParts(d: Date = koreaNow()) {
  const dow = d.getUTCDay();
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
    hour: d.getUTCHours(),
    minute: d.getUTCMinutes(),
    second: d.getUTCSeconds(),
    weekday: dow === 0 ? 7 : dow,
  };
}
