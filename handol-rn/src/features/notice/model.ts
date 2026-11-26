import { isoDate } from '@/core/utils/dateFormatter';
import { koreaNow } from '@/core/utils/koreaTime';

export interface Notice {
  id: number;
  url: string;
  title: string;
  author: string;
  /** 서버 createAt (ISO 8601) */
  createdAt: string;
}

/** 공지 API 는 분류를 주지 않아 부서·제목에 분류 이름이 들어 있는지로 거른다. */
export const NOTICE_FILTERS = [
  { key: 'all', label: '전체' },
  { key: 'academic', label: '학사' },
  { key: 'scholarship', label: '장학' },
  { key: 'extracurricular', label: '비교과' },
  { key: 'general', label: '일반' },
  { key: 'dormitory', label: '생활관' },
  { key: 'career', label: '취업' },
  { key: 'saved', label: '저장한 공지' },
] as const;

export type NoticeFilter = (typeof NOTICE_FILTERS)[number]['key'];

const KEYWORD_FILTERS: readonly NoticeFilter[] = ['academic', 'scholarship', 'extracurricular', 'career', 'general'];

const labelOf = (key: NoticeFilter): string => NOTICE_FILTERS.find((f) => f.key === key)?.label ?? '';

export const isKeywordFilter = (f: NoticeFilter): boolean => KEYWORD_FILTERS.includes(f);

/** 이 분류가 notice 를 보여 줄지. 키워드 분류가 아니면 항상 true. */
export function matchesFilter(filter: NoticeFilter, notice: Notice): boolean {
  if (!isKeywordFilter(filter)) return true;
  const text = `${notice.author} ${notice.title}`;
  if (filter === 'general') {
    return !KEYWORD_FILTERS.some((f) => f !== 'general' && text.includes(labelOf(f)));
  }
  return text.includes(labelOf(filter));
}

/** 분류와 검색어(제목·작성 부서)에 맞는 공지만 남긴다. */
export function filterNotices(items: Notice[], filter: NoticeFilter, query = ''): Notice[] {
  const q = query.trim().toLowerCase();
  return items.filter(
    (n) => matchesFilter(filter, n) && (q === '' || n.title.toLowerCase().includes(q) || n.author.toLowerCase().includes(q)),
  );
}

/** 부서 배지와 같은 [부서] 가 제목 앞에 또 붙어 있으면 뗀다. */
export function titleWithoutAuthor(notice: Notice): string {
  const prefix = `[${notice.author}]`;
  const title = notice.title.trimStart();
  if (!title.startsWith(prefix)) return notice.title;
  const rest = title.slice(prefix.length).trimStart();
  return rest === '' ? notice.title : rest;
}

/** 공지 id 가 있으면 id, 없으면(0 이하) url. */
export const keyOf = (notice: Notice): string => (notice.id > 0 ? String(notice.id) : notice.url);

// ── NEW 배지: 게시일이 최근 N일 안이고 '본 공지' 기록에 없는 공지 ──────────────

/** 게시일이 KST 기준 오늘 포함 이 일수 안이면 NEW 후보. */
export const NEW_WITHIN_DAYS = 3;

/** 공지 키 → 게시일(KST yyyy-MM-dd). null 은 첫 실행. */
export type SeenMap = Record<string, string>;

const HAS_ZONE = /(Z|[+-]\d{2}:?\d{2})$/i;
const DAY_MS = 24 * 60 * 60 * 1000;
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** 게시일의 KST 날짜(yyyy-MM-dd). 시간대 표기가 없으면 KST 벽시계로 본다. 못 읽으면 null. */
export function kstDateOf(createdAt: string): string | null {
  if (!HAS_ZONE.test(createdAt)) {
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(createdAt);
    return m ? `${m[1]}-${m[2]}-${m[3]}` : null;
  }
  const t = Date.parse(createdAt);
  return Number.isNaN(t) ? null : isoDate(new Date(t + KST_OFFSET_MS));
}

/** NEW 후보 기간의 첫 날짜. yyyy-MM-dd 라 문자열 비교가 날짜 비교다. */
export function newCutoff(now: Date = koreaNow()): string {
  return isoDate(new Date(now.getTime() - (NEW_WITHIN_DAYS - 1) * DAY_MS));
}

export function isNewNotice(notice: Notice, seen: SeenMap | null, cutoff: string = newCutoff()): boolean {
  const date = kstDateOf(notice.createdAt);
  if (date === null || date < cutoff) return false;
  return !(seen && keyOf(notice) in seen);
}

/** 목록을 떠나며 불러와 있던 공지를 본 공지로 기록한다. 기간 밖이 된 키는 버린다. */
export function nextSeen(seen: SeenMap | null, loaded: Notice[], cutoff: string = newCutoff()): SeenMap {
  const out: SeenMap = {};
  for (const [k, v] of Object.entries(seen ?? {})) if (v >= cutoff) out[k] = v;
  for (const n of loaded) {
    const date = kstDateOf(n.createdAt);
    if (date !== null && date >= cutoff) out[keyOf(n)] = date;
  }
  return out;
}
