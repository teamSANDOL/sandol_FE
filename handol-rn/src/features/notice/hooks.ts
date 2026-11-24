import { useInfiniteQuery } from '@tanstack/react-query';
import { fetchNoticePage, NOTICE_PAGE_SIZE, rememberNotices } from './api';

/** 일반 공지 / 생활관 공지 (같은 로직이라 isDormitory 로 나눈다) */
export function useNoticeList(isDormitory: boolean) {
  return useInfiniteQuery({
    queryKey: ['notice', 'list', isDormitory],
    initialPageParam: 1,
    queryFn: async ({ pageParam }) => {
      const page = await fetchNoticePage(isDormitory, pageParam);
      rememberNotices(page.items);
      return page;
    },
    getNextPageParam: (last) => (last.items.length >= NOTICE_PAGE_SIZE ? last.page + 1 : undefined),
  });
}
