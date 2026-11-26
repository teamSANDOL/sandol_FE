const pad = (n: number) => String(n).padStart(2, '0');

/** KST 벽시계 Date(getUTC*) 의 연 · 월 · 일을 "yyyy-MM-dd" 로 */
export function isoDate(d: Date): string {
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
}

/** ISO 8601 → "yyyy.MM.dd" (기기 시간대). 파싱 실패 시 원본 */
export function formatDate(raw: string): string {
  const t = Date.parse(raw);
  if (Number.isNaN(t)) return raw;
  const d = new Date(t);
  return `${d.getFullYear()}.${pad(d.getMonth() + 1)}.${pad(d.getDate())}`;
}

/** ISO 8601 → "yyyy. MM. dd." — 공지 시안 표기. 파싱 실패 시 원본 */
export function dottedDate(raw: string): string {
  const plain = formatDate(raw);
  if (plain === raw) return raw;
  return plain.replace(/\./g, '. ') + '.';
}
