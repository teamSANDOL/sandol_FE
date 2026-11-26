/**
 * quanect.kr 정책 페이지 HTML 에서 제목 · 조항 · 번호 항목을 뽑는다 (Flutter parsePolicyHtml).
 * 구조: `main > header(h1, p)` 다음에 조항마다 `section > h2 + p…`, 번호 항목은
 * `div.flex > span(머리표) + div(p…)` 이고 항목 안에 항목이 다시 들어간다.
 * HTML 은 WebView 로 실행하지 않고 텍스트만 추출해 네이티브로 다시 그린다(스크립트 실행 없음).
 */

export type PolicyBlock =
  | { isHeading: true; text: string }
  | { isHeading: false; text: string; /** 번호 항목 첫 단락의 `1.` `가.` */ marker: string | null; depth: number };

export type PolicyContent = { intro: string | null; blocks: PolicyBlock[] };

type El = { tag: string; classes: string[]; children: (El | string)[]; parent: El | null };

const VOID_TAGS = new Set(['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr']);
const TOKEN = /<!--[\s\S]*?-->|<(\/?)([a-zA-Z][\w:-]*)((?:"[^"]*"|'[^']*'|[^>"'])*)>|([^<]+|<)/g;
const ENTITIES: Record<string, string> = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' };

export function decodeEntities(s: string): string {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e: string) => {
    if (e[0] === '#') {
      const cp = e[1].toLowerCase() === 'x' ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
      return Number.isFinite(cp) && cp > 0 && cp <= 0x10ffff ? String.fromCodePoint(cp) : m;
    }
    return ENTITIES[e.toLowerCase()] ?? m;
  });
}

function parseDom(source: string): El {
  const body = source.replace(/<(script|style)\b[\s\S]*?<\/\1\s*>/gi, '');
  const root: El = { tag: '#root', classes: [], children: [], parent: null };
  let cur = root;
  for (const m of body.matchAll(TOKEN)) {
    const [, closing, rawTag, attrs, text] = m;
    if (text !== undefined) {
      cur.children.push(decodeEntities(text));
    } else if (rawTag) {
      const tag = rawTag.toLowerCase();
      if (closing) {
        for (let n: El | null = cur; n && n !== root; n = n.parent) {
          if (n.tag === tag) {
            cur = n.parent ?? root;
            break;
          }
        }
        continue;
      }
      const cls = /\bclass\s*=\s*(?:"([^"]*)"|'([^']*)')/i.exec(attrs);
      const el: El = { tag, classes: (cls?.[1] ?? cls?.[2] ?? '').split(/\s+/).filter(Boolean), children: [], parent: cur };
      cur.children.push(el);
      if (!VOID_TAGS.has(tag) && !/\/\s*$/.test(attrs)) cur = el;
    }
  }
  return root;
}

const isEl = (n: El | string): n is El => typeof n !== 'string';
const elChildren = (el: El): El[] => el.children.filter(isEl);

function textOf(el: El): string {
  return el.children.map((c) => (isEl(c) ? textOf(c) : c)).join('');
}
const clean = (s: string) => s.replace(/\s+/g, ' ').trim();

function descendants(el: El): El[] {
  return elChildren(el).flatMap((c) => [c, ...descendants(c)]);
}

function ancestors(el: El): El[] {
  const out: El[] = [];
  for (let p = el.parent; p; p = p.parent) out.push(p);
  return out;
}

const isListItem = (el: El) => {
  const kids = elChildren(el);
  return el.tag === 'div' && el.classes.includes('flex') && kids.length === 2 && kids[0].tag === 'span';
};

export function parsePolicyHtml(source: string): PolicyContent {
  const all = descendants(parseDom(source));
  const main = all.find((e) => e.tag === 'main');
  const nodes = main ? descendants(main) : [];
  const blocks: PolicyBlock[] = [];
  for (const el of nodes) {
    if ((el.tag !== 'h2' && el.tag !== 'p') || !ancestors(el).some((a) => a.tag === 'section')) continue;
    const text = clean(textOf(el));
    if (!text) continue;
    if (el.tag === 'h2') {
      blocks.push({ isHeading: true, text });
      continue;
    }
    const items = ancestors(el).filter(isListItem);
    const item = items[0];
    const isFirstPara = item !== undefined && descendants(item).find((d) => d.tag === 'p') === el;
    blocks.push({
      isHeading: false,
      text,
      depth: items.length,
      // 항목의 첫 단락에만 머리표를 붙인다.
      marker: isFirstPara ? clean(textOf(elChildren(item)[0])) : null,
    });
  }
  if (blocks.length === 0) throw new Error('정책 본문을 찾지 못했습니다');
  const header = nodes.find((e) => e.tag === 'header');
  const introEl = header && descendants(header).find((e) => e.tag === 'p');
  return { intro: introEl ? clean(textOf(introEl)) || null : null, blocks };
}
