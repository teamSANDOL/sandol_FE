import { useCallback, useEffect, useMemo, useState } from 'react';
import { AppState, StyleSheet, View } from 'react-native';
import { router, useFocusEffect } from 'expo-router';
import { useQueryClient, type InfiniteData } from '@tanstack/react-query';
import { AppTopBar, ErrorRetryView, GradientBackground, HText, LoadingIndicator, colors, metrics, spacing } from '@/design-system';
import type { NoticePage } from '../api';
import { FilterChips, SearchBox } from '../components/NoticeHeader';
import { NoticeList } from '../components/NoticeList';
import { refreshNoticeFirstPage, useNoticeList } from '../hooks';
import { filterNotices, isKeywordFilter, type Notice, type NoticeFilter } from '../model';
import { loadBookmarks, markSeen, useBookmarks } from '../storage';

/** 지금 불러와 있는 공지(전체 · 생활관) */
function loadedNotices(client: ReturnType<typeof useQueryClient>): Notice[] {
  return [false, true].flatMap(
    (isDormitory) =>
      client.getQueryData<InfiniteData<NoticePage>>(['notice', 'list', isDormitory])?.pages.flatMap((p) => p.items) ?? [],
  );
}

/** 공지 목록 (전체 · 분류 · 생활관). 분류와 검색은 지금까지 불러온 목록 안에서 거른다. */
function ListTab({ filter, query }: { filter: NoticeFilter; query: string }) {
  const isDormitory = filter === 'dormitory';
  const list = useNoticeList(isDormitory);
  const client = useQueryClient();
  const items = useMemo(
    () => filterNotices(list.data?.pages.flatMap((p) => p.items) ?? [], filter, query),
    [list.data, filter, query],
  );
  if (list.isPending) {
    return (
      <View style={styles.center}>
        <LoadingIndicator />
      </View>
    );
  }
  // 다음 페이지만 실패하면 불러온 목록은 그대로 둔다(Flutter loadNextPage 는 실패를 삼킨다)
  if (!list.data) return <ErrorRetryView title="공지사항을 불러올 수 없습니다." onRetry={() => void list.refetch()} />;
  // 거르지 않았을 때만 서버가 센 전체 건수를 그대로 보여 준다.
  const narrowed = isKeywordFilter(filter) || query.trim() !== '';
  const total = narrowed ? items.length : (list.data.pages.at(-1)?.total ?? 0);
  return (
    <NoticeList
      items={items}
      total={total}
      isLoadingMore={list.isFetchingNextPage}
      onEndReached={() => {
        if (list.hasNextPage && !list.isFetchingNextPage) void list.fetchNextPage({ cancelRefetch: false });
      }}
      isRefreshing={list.isRefetching && !list.isFetchingNextPage}
      onRefresh={() => void refreshNoticeFirstPage(client, isDormitory)}
    />
  );
}

function SavedTab({ query }: { query: string }) {
  const items = filterNotices(useBookmarks(), 'saved', query);
  return <NoticeList items={items} total={items.length} emptyText="저장한 공지가 없습니다." />;
}

/** 공지사항 탭 (Figma 공지사항2): 검색창 · 분류 칩 · 공지별 카드 */
export default function NoticeScreen() {
  const [filter, setFilter] = useState<NoticeFilter>('all');
  const [query, setQuery] = useState('');
  const client = useQueryClient();

  useEffect(() => {
    void loadBookmarks();
  }, []);

  // 목록을 떠나면(다른 화면·탭으로 이동, 앱이 백그라운드로) 불러온 공지를 '본 공지'로 남긴다.
  useFocusEffect(
    useCallback(() => {
      const sub = AppState.addEventListener('change', (s) => {
        if (s === 'background') void markSeen(loadedNotices(client));
      });
      return () => {
        sub.remove();
        void markSeen(loadedNotices(client));
      };
    }, [client]),
  );

  return (
    <GradientBackground>
      <AppTopBar
        title="공지사항"
        titleNode={<HText variant="title">공지사항</HText>}
        onBack={() => router.navigate('/home')}
        backgroundColor={colors.transparent}
        horizontalPadding={metrics.pageGutter - 10}
      />
      <View style={styles.search}>
        <SearchBox value={query} onChange={setQuery} />
      </View>
      <View style={styles.chips}>
        <FilterChips selected={filter} onSelect={setFilter} />
      </View>
      <View style={styles.flex}>
        {/* 분류를 바꾸면 스크롤 위치도 새로 시작한다(key). */}
        {filter === 'saved' ? <SavedTab query={query} /> : <ListTab key={filter} filter={filter} query={query} />}
      </View>
    </GradientBackground>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  search: { paddingHorizontal: metrics.pageGutter, paddingTop: 38 },
  chips: { paddingHorizontal: metrics.pageGutter, paddingTop: 12 },
});
