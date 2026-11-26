import { DIRECTIONS, isSegment, viaSchool, type ShuttleDayType, type ShuttleDirection, type ShuttleEntry, type ShuttleStops } from './model';

/** 글자 사이에 폭 없는 공백(U+200B)을 넣어 어절 중간에서도 줄바꿈되게 한다. Flutter 는 한글을 글자 단위로 줄바꿈하지만 RN 은 어절 단위라 줄 수가 달라진다 */
export const breakAnywhere = (text: string): string => text.replace(/(\S)(?=\S)/g, '$1\u200B');

/** 시간표에서 이미 지나간 줄인지. 구간은 끝 시각이 지났을 때, 정시편은 출발 시각이 지났을 때 */
export function isPastEntry(e: ShuttleEntry, nowMinutes: number): boolean {
  return isSegment(e) ? e.end !== undefined && e.end <= nowMinutes : e.start < nowMinutes;
}

export function dayLabel(type: ShuttleDayType): string {
  switch (type) {
    case 'weekday':
      return '평일';
    case 'saturday':
      return '토요일';
    case 'sunday':
      return '일요일';
    case 'holiday':
      return '공휴일';
  }
}

/** 시간표 카드 제목 `출발 → 도착` (Figma 2905:2318) */
export function routeTitle(d: ShuttleDirection, stops: ShuttleStops): string {
  const { origin, destination } = DIRECTIONS[d];
  const via = viaSchool(d) ? ` (${stops.main_campus?.name ?? ''} 경유)` : '';
  return `${stops[origin]?.name ?? ''} → ${stops[destination]?.name ?? ''}${via}`;
}

/** 맨 아래 안내문 (2683:2995) */
export function footerText(now: Date, needsReview: boolean): string {
  const hh = String(now.getUTCHours()).padStart(2, '0');
  const mm = String(now.getUTCMinutes()).padStart(2, '0');
  const review = needsReview ? '\n최신 시간표를 확인 중이라 실제와 다를 수 있어요.' : '';
  return `시간표는 학교 사정에 따라 변경될 수 있어요.${review}\n마지막 업데이트 • 오늘 ${hh}:${mm}`;
}
