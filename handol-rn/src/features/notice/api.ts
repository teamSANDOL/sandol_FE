import { api } from '@/core/api/client';
import type { Notice } from './model';

const PAGE_SIZE = 10;

interface NoticeItemDto {
  id: number;
  url: string;
  title: string;
  author: string;
  /** 서버 필드명 그대로(createAt). 항목당 100~280KB 인 html 은 받아도 쓰지 않는다. */
  createAt: string;
}

interface PaginatedNoticeDto {
  items: NoticeItemDto[];
  total: number;
  page: number;
  size: number;
}

export interface NoticePage {
  items: Notice[];
  total: number;
  page: number;
}

const noticeCache = new Map<string, Notice>();

/** 상세 화면이 id 로 공지를 꺼내 쓰도록 목록에서 본 공지를 메모리에 둔다. */
export function cachedNotice(key: string): Notice | undefined {
  return noticeCache.get(key);
}

export function toNotice(d: NoticeItemDto): Notice {
  return { id: d.id, url: d.url, title: d.title, author: d.author, createdAt: d.createAt };
}

export async function fetchNoticePage(isDormitory: boolean, page: number): Promise<NoticePage> {
  const path = isDormitory ? '/notice-notification/dormitory-notice' : '/notice-notification/notice';
  const res = await api.get<PaginatedNoticeDto>(path, { query: { page, size: PAGE_SIZE } });
  return { items: res.items.map(toNotice), total: res.total, page };
}

export function rememberNotices(items: Notice[]): void {
  for (const n of items) noticeCache.set(n.id > 0 ? String(n.id) : n.url, n);
}

/** 서버가 센 한 페이지 크기. 이만큼 받았으면 다음 페이지가 있다고 본다. */
export const NOTICE_PAGE_SIZE = PAGE_SIZE;
