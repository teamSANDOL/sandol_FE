import type { Href } from 'expo-router';
import { keyOf, type Notice } from '../notice/model';

/** 알림을 눌렀을 때 열 화면. 공지는 상세 화면이 찾도록 공지 자체도 싣는다. */
export type PushTarget = { href: Href; notice?: Notice };

/** `route` 키로 열 수 있는 탭. 목록에 없는 경로는 무시한다(임의 딥링크 차단). */
const TAB_ROUTES = new Set(['/home', '/meal', '/bus', '/notice', '/map']);

/** 공지 상세는 WebView 로 url 을 그대로 열므로 학교 도메인 https 만 허용한다. */
export function isSchoolUrl(url: string): boolean {
  return /^https:\/\/([a-z0-9-]+\.)*tukorea\.ac\.kr([/?#]|$)/i.test(url);
}

const str = (v: unknown): string => (typeof v === 'string' ? v : '');

/** 알림 data → 이동할 화면. 약속(docs/PUSH.md 3장)에 맞지 않으면 null. data 값은 모두 문자열이다. */
export function pushTargetFrom(data: unknown): PushTarget | null {
  if (!data || typeof data !== 'object') return null;
  const d = data as Record<string, unknown>;
  if (d.type === 'notice') {
    const id = Number(d.id);
    const url = str(d.url);
    if (!Number.isInteger(id) || id <= 0 || !isSchoolUrl(url) || typeof d.title !== 'string') return null;
    const notice: Notice = { id, url, title: d.title, author: str(d.author), createdAt: str(d.created_at) };
    return { href: { pathname: '/notice/detail', params: { id: keyOf(notice) } }, notice };
  }
  return typeof d.route === 'string' && TAB_ROUTES.has(d.route) ? { href: d.route as Href } : null;
}
