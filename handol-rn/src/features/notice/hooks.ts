import { useInfiniteQuery, type InfiniteData, type QueryClient } from '@tanstack/react-query';
import { fetchNoticePage, NOTICE_PAGE_SIZE, rememberNotices, type NoticePage } from './api';

const noticeListKey = (isDormitory: boolean) => ['notice', 'list', isDormitory] as const;

/** 일반 공지 / 생활관 공지 (같은 로직이라 isDormitory 로 나눈다) */
export function useNoticeList(isDormitory: boolean) {
  return useInfiniteQuery({
    queryKey: noticeListKey(isDormitory),
    initialPageParam: 1,
    queryFn: async ({ pageParam }) => {
      const page = await fetchNoticePage(isDormitory, pageParam);
      rememberNotices(page.items);
      return page;
    },
    getNextPageParam: (last) => (last.items.length >= NOTICE_PAGE_SIZE ? last.page + 1 : undefined),
  });
}

/** 당겨서 새로고침: 불러온 뒤쪽 페이지는 버리고 1페이지만 다시 받는다(Flutter NoticeListNotifier.refresh) */
export function refreshNoticeFirstPage(client: QueryClient, isDormitory: boolean): Promise<void> {
  const queryKey = noticeListKey(isDormitory);
  client.setQueryData<InfiniteData<NoticePage>>(queryKey, (d) => d && { pages: d.pages.slice(0, 1), pageParams: d.pageParams.slice(0, 1) });
  return client.refetchQueries({ queryKey, exact: true });
}
