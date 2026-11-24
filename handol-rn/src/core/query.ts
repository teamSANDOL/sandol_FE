import { QueryCache, QueryClient } from '@tanstack/react-query';

/** 앱 전역 서버 상태 캐시. 개발 빌드에서는 실패한 쿼리를 Metro 로그로 남긴다. */
export const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (error, query) => {
      if (__DEV__) console.warn('[query]', JSON.stringify(query.queryKey), error instanceof Error ? `${error.name}: ${error.message}\n${(error.stack ?? '').split('\n').slice(0, 6).join('\n')}` : String(error));
    },
  }),
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 60_000,
      refetchOnWindowFocus: false,
    },
  },
});
