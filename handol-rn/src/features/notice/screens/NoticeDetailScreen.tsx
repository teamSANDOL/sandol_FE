import { useRef, useState, type ComponentRef } from 'react';
import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router, useLocalSearchParams } from 'expo-router';
import { WebView } from 'react-native-webview';
import { openExternalLink } from '@/core/utils/externalLink';
import { HPressable, HText, Icon, LoadingIndicator, colors, radius } from '@/design-system';
import { cachedNotice } from '../api';
import { RefreshIcon } from '../components/NoticeIcons';
import { keyOf } from '../model';
import { useBookmarks } from '../storage';

const isWebUrl = (url: string): boolean => /^https?:\/\//i.test(url);

/** 공지 상세: 공지 원문 페이지를 WebView 로 연다. 상단에 뒤로가기 · 제목 · 새로고침. */
export default function NoticeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const web = useRef<ComponentRef<typeof WebView>>(null);
  const [isLoading, setIsLoading] = useState(true);
  const bookmarks = useBookmarks();
  const notice = cachedNotice(id) ?? bookmarks.find((n) => keyOf(n) === id);

  return (
    <View style={[styles.screen, { paddingTop: insets.top }]}>
      <View style={styles.bar}>
        <View style={styles.backShadow}>
          <HPressable accessibilityRole="button" accessibilityLabel="뒤로" onPress={() => router.back()} style={styles.back}>
            <Icon name="backArrow" />
          </HPressable>
        </View>
        <View style={styles.titleBox}>
          <HText variant="body" weight="bold" numberOfLines={1} style={styles.titleText}>
            {notice?.title ?? '공지사항'}
          </HText>
          <HPressable accessibilityRole="button" accessibilityLabel="새로고침" onPress={() => web.current?.reload()} borderless style={styles.refresh}>
            <RefreshIcon size={20} color={colors.muted} />
          </HPressable>
        </View>
      </View>
      {notice && isWebUrl(notice.url) ? (
        <View style={styles.flex}>
          <WebView
            ref={web}
            source={{ uri: notice.url }}
            javaScriptEnabled
            originWhitelist={['https://*', 'http://*']}
            onLoadStart={() => setIsLoading(true)}
            onLoadEnd={() => setIsLoading(false)}
            onShouldStartLoadWithRequest={(req: { url: string }) => {
              if (isWebUrl(req.url)) return true;
              void openExternalLink(req.url);
              return false;
            }}
          />
          {isLoading && (
            <View style={styles.loading} pointerEvents="none">
              <LoadingIndicator />
            </View>
          )}
        </View>
      ) : (
        <HText variant="caption" tone="muted" style={styles.missing}>
          공지를 불러올 수 없습니다.
        </HText>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  /** Material titleMedium(16, 자간 0.15) 굵게 */
  titleText: { flex: 1, letterSpacing: 0.15, lineHeight: undefined },
  bar: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingLeft: 12, paddingRight: 12, paddingTop: 8, paddingBottom: 10 },
  backShadow: { borderRadius: radius.md, backgroundColor: colors.background, elevation: 2 },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center', borderRadius: radius.md, overflow: 'hidden' },
  titleBox: { flex: 1, height: 44, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, backgroundColor: colors.background, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border, elevation: 2 },
  refresh: { width: 28, height: 28, alignItems: 'center', justifyContent: 'center' },
  loading: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center' },
  missing: { textAlign: 'center', paddingVertical: 60 },
});
