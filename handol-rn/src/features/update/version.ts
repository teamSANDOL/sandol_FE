/** "v0.3.23" · "0.3.23" → [0, 3, 23]. 형식이 아니면 null (릴리스 태그는 외부 값이라 검사한다) */
export function parseVersion(tag: string): number[] | null {
  const m = /^v?(\d+(?:\.\d+){0,3})$/.exec(tag.trim());
  return m ? m[1].split('.').map(Number) : null;
}

/** latest 가 current 보다 새 버전이면 true. 둘 중 하나라도 형식이 아니면 false */
export function isNewerVersion(latest: string, current: string): boolean {
  const a = parseVersion(latest);
  const b = parseVersion(current);
  if (!a || !b) return false;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const d = (a[i] ?? 0) - (b[i] ?? 0);
    if (d !== 0) return d > 0;
  }
  return false;
}
