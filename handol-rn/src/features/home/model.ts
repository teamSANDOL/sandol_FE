import { resolveAssetUrl } from '@/core/assetUrl';

/** 홈 배너 한 장 (Flutter HomeBanner). 필드는 BFF 응답(docs/BFF_APP_CONTENT.md)과 같다. */
export type BannerLink = { kind: 'external'; url: string } | { kind: 'app'; location: string };

export type HomeBanner = {
  /** 서버 배너 id. 앱 내장 배너는 없다 */
  id?: string;
  /** 글자 카드의 제목. 그림 카드에선 화면 읽기용 광고 내용 */
  title: string;
  body?: string;
  /** 앱 내장 그림 (require 모듈) */
  image?: number;
  /** 서버 그림. 있으면 image 보다 먼저 */
  imageUrl?: string;
  /** 글자 카드 오른쪽 아이콘 */
  icon?: 'navMeal' | 'navBus' | 'navMap' | 'navNotice' | 'orgPhone';
  /** 누르면 갈 곳. 없으면 눌리지 않는다 */
  link?: BannerLink;
};

/** 하단 탭 루트 */
export const TAB_ROUTES: readonly string[] = ['/home', '/meal', '/bus', '/notice', '/map'];

/** 배너로 열 수 있는 앱 화면 */
export const APP_ROUTES: readonly string[] = [...TAB_ROUTES, '/home/organization', '/user', '/user/announcements', '/user/faq', '/user/guide'];

export const isImageBanner = (b: HomeBanner): boolean => b.image !== undefined || b.imageUrl !== undefined;

export const isTabRoute = (location: string): boolean => TAB_ROUTES.includes(location.split('?')[0]);

/**
 * 서버가 주는 문자열 하나를 링크로. https 는 외부 브라우저, / 로 시작하는 허용 경로는 앱 화면.
 * 약속에 맞지 않는 값은 undefined (눌리지 않는 배너).
 */
export function parseBannerLink(raw: string | null | undefined): BannerLink | undefined {
  const value = raw?.trim();
  if (!value) return undefined;
  if (/^https:\/\/[^/\s]+/i.test(value)) return { kind: 'external', url: value };
  if (value.startsWith('/') && !value.startsWith('//') && APP_ROUTES.includes(value.split('?')[0])) {
    return { kind: 'app', location: value };
  }
  return undefined;
}

/** 글자 배너 아이콘은 서버 SVG 대신 링크 화면의 앱 아이콘을 쓴다 */
const LINK_ICONS: Record<string, NonNullable<HomeBanner['icon']>> = {
  '/meal': 'navMeal',
  '/bus': 'navBus',
  '/map': 'navMap',
  '/notice': 'navNotice',
  '/home/organization': 'orgPhone',
};

const text = (v: unknown): string | undefined => (typeof v === 'string' && v.trim() ? v.trim() : undefined);

/**
 * BFF `home_banners` 한 항목 (docs/BFF_APP_CONTENT.md 4.2). 형식이 틀리거나 게시 기간 밖이면 undefined.
 * image: 345:138 그림 한 장(https 또는 BFF 업로드 경로). text: 제목·설명을 앱이 그린다.
 */
export function parseServerBanner(raw: unknown, assetBase: string, now: number = Date.now()): HomeBanner | undefined {
  if (!raw || typeof raw !== 'object') return undefined;
  const r = raw as Record<string, unknown>;
  const id = text(r.id);
  const title = text(r.title);
  if (!id || !title) return undefined;
  const startsAt = Date.parse(text(r.starts_at) ?? '');
  const endsAt = Date.parse(text(r.ends_at) ?? '');
  if (startsAt > now || endsAt < now) return undefined;
  const link = parseBannerLink(text(r.link));
  if (r.kind === 'image') {
    const imageUrl = resolveAssetUrl(text(r.image_url), assetBase);
    return imageUrl ? { id, title, imageUrl, link } : undefined;
  }
  if (r.kind !== 'text') return undefined;
  const icon = link?.kind === 'app' ? LINK_ICONS[link.location.split('?')[0]] : undefined;
  return { id, title, body: text(r.body), icon, link };
}

export function parseServerBanners(raw: unknown, assetBase: string, now: number = Date.now()): HomeBanner[] {
  return Array.isArray(raw) ? raw.flatMap((b) => parseServerBanner(b, assetBase, now) ?? []) : [];
}
