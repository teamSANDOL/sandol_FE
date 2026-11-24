/** 조직도 도메인 모델과 순수 로직 (Flutter organization_node / organization_search_result / organization_provider). */

export type OrganizationUnit = { kind: 'unit'; name: string; phone?: string | null; url?: string | null };
export type OrganizationGroup = { kind: 'group'; name: string; children: OrganizationNode[] };
export type OrganizationNode = OrganizationUnit | OrganizationGroup;

export type OrganizationSearchResult = { node: OrganizationNode; /** 상위 그룹 이름. 예: ['대학본부', '교무처'] */ path: string[] };

/** 홈 카드에 고정해 둔 부서. 이 순서대로 보여준다. 교무처는 번호 없는 그룹이라 대표 번호를 가진 교무팀을 쓴다. */
export const PINNED_ORGANIZATION_UNITS = ['입학관리팀', '홍보소통팀', '교무팀'] as const;

function asRecord(v: unknown): Record<string, unknown> | null {
  return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : null;
}

function optString(v: unknown): string | null {
  return typeof v === 'string' ? v : null;
}

/** 서버 JSON(group/unit 재귀) → 도메인 노드. 객체가 아닌 값은 이름만 있는 부서로 본다. */
export function parseOrganizationNode(raw: unknown): OrganizationNode {
  const obj = asRecord(raw);
  if (!obj) return { kind: 'unit', name: String(raw) };
  const name = optString(obj.name) ?? '';
  if (obj.type === 'unit') return { kind: 'unit', name, phone: optString(obj.phone), url: optString(obj.url) };
  const subunits = asRecord(obj.subunits) ?? {};
  return { kind: 'group', name, children: Object.values(subunits).map(parseOrganizationNode) };
}

export function parseOrganizationTree(raw: unknown): OrganizationGroup {
  const node = parseOrganizationNode(raw);
  return node.kind === 'group' ? node : { kind: 'group', name: node.name, children: [node] };
}

/** `03180411092` → `031-8041-1092`. 형식이 다르면 원문 그대로. */
export function formatPhone(raw: string): string {
  const d = raw.replace(/\D/g, '');
  if (d.length === 11) return `${d.slice(0, 3)}-${d.slice(3, 7)}-${d.slice(7)}`;
  if (d.length === 10) {
    return d.startsWith('02')
      ? `${d.slice(0, 2)}-${d.slice(2, 6)}-${d.slice(6)}`
      : `${d.slice(0, 3)}-${d.slice(3, 6)}-${d.slice(6)}`;
  }
  if (d.length === 9 && d.startsWith('02')) return `${d.slice(0, 2)}-${d.slice(2, 5)}-${d.slice(5)}`;
  return raw;
}

const normalize = (s: string) => s.replace(/\s+/g, '').toLowerCase();

/**
 * 받아 둔 트리를 앱 안에서 부분일치로 검색한다(서버 검색은 완전일치뿐).
 * 이름: 공백 제거 + 대소문자 무시 contains. 숫자만 입력하면 전화번호(숫자만)에도 contains.
 */
export function searchOrganizationTree(root: OrganizationGroup, query: string): OrganizationSearchResult[] {
  const q = normalize(query);
  if (!q) return [];
  const digitQuery = /^\d+$/.test(q) ? q : null;
  const results: OrganizationSearchResult[] = [];

  const visit = (node: OrganizationNode, path: string[]) => {
    const nameHit = normalize(node.name).includes(q);
    const phoneHit =
      digitQuery !== null && node.kind === 'unit' && !!node.phone && node.phone.replace(/\D/g, '').includes(digitQuery);
    if (nameHit || phoneHit) results.push({ node, path });
    if (node.kind === 'group') {
      const childPath = [...path, node.name];
      node.children.forEach((c) => visit(c, childPath));
    }
  };
  root.children.forEach((c) => visit(c, []));
  return results;
}

/** 트리 전체를 깊이 우선으로 평탄화한 부서 목록 */
export function flattenUnits(root: OrganizationGroup): OrganizationUnit[] {
  const out: OrganizationUnit[] = [];
  const visit = (n: OrganizationNode) => {
    if (n.kind === 'unit') out.push(n);
    else n.children.forEach(visit);
  };
  visit(root);
  return out;
}

/** 고정 부서 중 트리에 있고 전화번호가 있는 부서. 같은 이름은 먼저 나온 것. */
export function pinnedUnits(root: OrganizationGroup): OrganizationUnit[] {
  const byName = new Map<string, OrganizationUnit>();
  for (const u of flattenUnits(root)) if (u.phone && !byName.has(u.name)) byName.set(u.name, u);
  return PINNED_ORGANIZATION_UNITS.flatMap((name) => byName.get(name) ?? []);
}
