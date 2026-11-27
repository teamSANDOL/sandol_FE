import { useQuery } from '@tanstack/react-query';
import { api } from '@/core/api/client';
import { env } from '@/core/env';

/** BFF 서비스 공지 (docs/BFF_APP_CONTENT.md 6장). 모두 인증 없음 */
export type Announcement = {
  id: string;
  category: string;
  title: string;
  pinned: boolean;
  published_at: string;
  /** 상세에서만 (Markdown) */
  body?: string;
};
export type Faq = { id: string; question: string; answer: string; order: number };
export type ServiceGuide = { body: string; updated_at: string | null };

const get = <T>(path: string, query?: Record<string, number>) => api.get<T>(`${env.bffBaseUrl}/app/v1/${path}`, { auth: false, query });

export const CATEGORY_LABELS: Record<string, string> = { update: '업데이트', maintenance: '점검', notice: '안내', policy: '약관' };

/** 2026-11-25T06:25:15+09:00 → 2026.11.25 */
export const formatDate = (iso: string | null | undefined): string => (iso ?? '').slice(0, 10).replace(/-/g, '.');

// ponytail: 첫 50개만 받는다. 공지가 더 쌓이면 next_cursor 로 이어 받기를 붙인다.
export const useAnnouncements = () =>
  useQuery({ queryKey: ['support', 'announcements'], queryFn: () => get<{ items: Announcement[] }>('announcements', { limit: 50 }).then((r) => r.items) });

export const useAnnouncement = (id: string) =>
  useQuery({ queryKey: ['support', 'announcement', id], queryFn: () => get<Announcement>(`announcements/${encodeURIComponent(id)}`) });

export const useFaqs = () =>
  useQuery({ queryKey: ['support', 'faqs'], queryFn: () => get<Faq[]>('faqs').then((r) => [...r].sort((a, b) => a.order - b.order)) });

export const useServiceGuide = () => useQuery({ queryKey: ['support', 'guide'], queryFn: () => get<ServiceGuide>('service-guide') });
