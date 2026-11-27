/**
 * 서버가 준 그림 주소를 https 절대 주소로. BFF 업로드 그림은 `/app/v1/assets/<name>` 상대 경로나
 * 이름만 올 수 있어 base(BFF) 에 붙인다. https 가 아닌 절대 주소(http·data·javascript 등)는 버린다.
 */
export function resolveAssetUrl(raw: string | null | undefined, base: string): string | undefined {
  const v = raw?.trim();
  if (!v) return undefined;
  if (/^https:\/\/[^/\s]+/i.test(v)) return v;
  const root = base.replace(/\/+$/, '');
  if (v.startsWith('/') && !v.startsWith('//')) return root + v;
  if (/^[\w.-]+$/.test(v)) return `${root}/app/v1/assets/${v}`;
  return undefined;
}
