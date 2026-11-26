import { useCallback } from 'react';
import { FlatList, RefreshControl, StyleSheet, View } from 'react-native';
import { router } from 'expo-router';
import { HText, LoadingIndicator, colors, metrics, spacing } from '@/design-system';
import { isNewNotice, keyOf, newCutoff, type Notice } from '../model';
import { toggleBookmark, useBookmarks, useSeen } from '../storage';
import { NoticeCard } from './NoticeCard';
import { SummaryRow } from './NoticeHeader';

/** 목록 끝에서 이만큼(px) 안으로 스크롤하면 다음 페이지를 부른다(Flutter _pagingController) */
const LOAD_MORE_EXTENT = 300;

/** 요약 줄('최신 공지 · 총 N건 · 최신순') 아래에 공지 카드를 늘어놓는다. */
export function NoticeList({
  items,
  total,
  isLoadingMore = false,
  onEndReached,
  onRefresh,
  isRefreshing = false,
  emptyText = '공지사항이 없습니다.',
}: {
  items: Notice[];
  total: number;
  isLoadingMore?: boolean;
  onEndReached?: () => void;
  onRefresh?: () => void;
  isRefreshing?: boolean;
  emptyText?: string;
}) {
  const bookmarks = useBookmarks();
  const seen = useSeen();
  const cutoff = newCutoff();
  const open = useCallback((n: Notice) => router.push({ pathname: '/notice/detail', params: { id: keyOf(n) } }), []);

  return (
    <FlatList
      data={items}
      keyExtractor={keyOf}
      contentContainerStyle={styles.content}
      ItemSeparatorComponent={Gap}
      ListHeaderComponent={<SummaryRow total={total} />}
      ListEmptyComponent={
        <HText variant="caption" tone="muted" style={styles.empty}>
          {emptyText}
        </HText>
      }
      ListFooterComponent={
        isLoadingMore ? (
          <View style={styles.more}>
            <LoadingIndicator />
          </View>
        ) : undefined
      }
      // 스크롤할 때만 확인한다: 사용자가 스크롤하기 전엔 다음 페이지를 부르지 않는다
      onScroll={
        onEndReached
          ? ({ nativeEvent: { contentOffset, contentSize, layoutMeasurement } }) => {
              if (contentSize.height - layoutMeasurement.height - contentOffset.y <= LOAD_MORE_EXTENT) onEndReached();
            }
          : undefined
      }
      scrollEventThrottle={16}
      refreshControl={
        onRefresh ? (
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} colors={[colors.primary]} progressBackgroundColor={colors.background} />
        ) : undefined
      }
      renderItem={({ item }) => (
        <NoticeCard
          notice={item}
          isSaved={bookmarks.some((b) => b.id === item.id)}
          isNew={isNewNotice(item, seen, cutoff)}
          onToggleSaved={() => void toggleBookmark(item)}
          onPress={() => open(item)}
        />
      )}
    />
  );
}

const Gap = () => <View style={{ height: spacing.sm }} />;

const styles = StyleSheet.create({
  content: { paddingHorizontal: metrics.pageGutter, paddingTop: spacing.md, paddingBottom: spacing.xl },
  empty: { textAlign: 'center', paddingVertical: 60 },
  more: { padding: spacing.md, alignItems: 'center' },
});
