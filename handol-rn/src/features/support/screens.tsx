import { useState, type ReactNode } from 'react';
import { Image } from 'expo-image';
import { env } from '@/core/env';
import { StyleSheet, View } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTopBar, Chevron, ErrorRetryView, GradientScrollView, HandolCard, HPressable, HText, LoadingIndicator, colors, metrics, radius, spacing } from '@/design-system';
import { DocBlock } from '@/features/user/components/DocBlocks';
import { CATEGORY_LABELS, formatDate, useAnnouncement, useAnnouncements, useFaqs, useServiceGuide } from './api';
import { parseMarkdown } from './markdown';

/** 본문 그림. 받은 뒤 원본 비율로 폭에 맞춘다 */
function BodyImage({ url, alt }: { url: string; alt: string }) {
  const [ratio, setRatio] = useState(16 / 9);
  return (
    <Image
      source={{ uri: url }}
      contentFit="contain"
      transition={120}
      accessibilityLabel={alt || '공지 그림'}
      onLoad={(e) => {
        if (e.source.width > 0 && e.source.height > 0) setRatio(e.source.width / e.source.height);
      }}
      style={{ width: '100%', aspectRatio: ratio, marginTop: spacing.sm, borderRadius: radius.md, backgroundColor: colors.primarySoft }}
    />
  );
}

/** Markdown 본문 (글 블록은 정책 문서와 같은 모양) */
function MarkdownBody({ source }: { source: string }) {
  return (
    <>
      {parseMarkdown(source, env.bffBaseUrl).map((b, i) => ('image' in b ? <BodyImage key={i} url={b.image} alt={b.alt} /> : <DocBlock key={i} block={b} />))}
    </>
  );
}

type QueryState = { data?: unknown; isError: boolean; refetch: () => unknown };

/** 상단 바 + 불러오기·오류·본문. 정책 문서 화면(PolicyScreen)과 같은 틀 */
function SupportFrame({ title, query, children }: { title: string; query: QueryState; children: () => ReactNode }) {
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar title={title} titleNode={<HText variant="title">{title}</HText>} onBack={() => router.back()} showUser={false} horizontalPadding={metrics.pageGutter - 10} />
      {query.data !== undefined ? (
        <GradientScrollView contentContainerStyle={{ paddingHorizontal: metrics.pageGutter, paddingTop: spacing.md, paddingBottom: spacing.xl + insets.bottom, gap: spacing.md }}>
          {children()}
        </GradientScrollView>
      ) : query.isError ? (
        <ErrorRetryView title={`${title}을(를) 불러오지 못했어요`} onRetry={() => void query.refetch()} />
      ) : (
        <View style={styles.center}>
          <LoadingIndicator />
        </View>
      )}
    </View>
  );
}

function Empty({ text }: { text: string }) {
  return (
    <HText variant="body" tone="muted" style={{ textAlign: 'center', marginTop: spacing.xl }}>
      {text}
    </HText>
  );
}

const cardContent = { paddingHorizontal: metrics.cardInset, paddingVertical: spacing.md };

/** 마이 > 공지사항: 고정 글 → 최신순 */
export function AnnouncementListScreen() {
  const query = useAnnouncements();
  return (
    <SupportFrame title="공지사항" query={query}>
      {() =>
        query.data?.length ? (
          <HandolCard contentStyle={{ paddingHorizontal: metrics.cardInset, paddingVertical: spacing.xs }}>
            {query.data.map((a, i) => (
              <View key={a.id} style={[styles.clip, i > 0 && styles.divider]}>
                <HPressable accessibilityRole="button" onPress={() => router.push(`/user/announcements/${a.id}`)} style={styles.row}>
                  <View style={{ flex: 1, gap: 4 }}>
                    <HText variant="caption" tone="accent">
                      {[a.pinned ? '고정' : null, CATEGORY_LABELS[a.category] ?? null].filter(Boolean).join(' · ')}
                    </HText>
                    <HText variant="headline" keepAll numberOfLines={2}>
                      {a.title}
                    </HText>
                    <HText variant="caption" tone="muted">
                      {formatDate(a.published_at)}
                    </HText>
                  </View>
                  <Chevron muted color={colors.border} />
                </HPressable>
              </View>
            ))}
          </HandolCard>
        ) : (
          <Empty text="아직 공지가 없어요" />
        )
      }
    </SupportFrame>
  );
}

export function AnnouncementDetailScreen() {
  const { id } = useLocalSearchParams<{ id?: string }>();
  const query = useAnnouncement(String(id ?? ''));
  const a = query.data;
  return (
    <SupportFrame title="공지사항" query={query}>
      {() =>
        a && (
          <HandolCard contentStyle={{ ...cardContent, paddingBottom: spacing.lg }}>
            <HText variant="caption" tone="accent">
              {CATEGORY_LABELS[a.category] ?? ''}
            </HText>
            <HText variant="title" keepAll style={{ marginTop: 4 }}>
              {a.title}
            </HText>
            <HText variant="caption" tone="muted" style={{ marginTop: 4, marginBottom: spacing.sm }}>
              {formatDate(a.published_at)}
            </HText>
            <MarkdownBody source={a.body ?? ''} />
          </HandolCard>
        )
      }
    </SupportFrame>
  );
}

/** 마이 > 자주 묻는 질문: 질문을 누르면 답이 펼쳐진다 */
export function FaqScreen() {
  const query = useFaqs();
  const [openId, setOpenId] = useState<string | null>(null);
  return (
    <SupportFrame title="자주 묻는 질문" query={query}>
      {() =>
        query.data?.length ? (
          query.data.map((f) => {
            const isOpen = openId === f.id;
            return (
              <HandolCard key={f.id} contentStyle={{ paddingHorizontal: metrics.cardInset, paddingVertical: spacing.xs }}>
                <View style={styles.clip}>
                  <HPressable accessibilityRole="button" accessibilityState={{ expanded: isOpen }} onPress={() => setOpenId(isOpen ? null : f.id)} style={styles.row}>
                    <HText variant="headline" keepAll style={{ flex: 1 }}>
                      Q. {f.question}
                    </HText>
                    <View style={{ transform: [{ rotate: isOpen ? '-90deg' : '90deg' }] }}>
                      <Chevron muted color={colors.border} />
                    </View>
                  </HPressable>
                </View>
                {isOpen && (
                  <View style={{ paddingBottom: spacing.md }}>
                    <MarkdownBody source={f.answer} />
                  </View>
                )}
              </HandolCard>
            );
          })
        ) : (
          <Empty text="아직 등록된 질문이 없어요" />
        )
      }
    </SupportFrame>
  );
}

export function ServiceGuideScreen() {
  const query = useServiceGuide();
  return (
    <SupportFrame title="서비스 안내" query={query}>
      {() =>
        query.data && (
          <HandolCard contentStyle={{ ...cardContent, paddingBottom: spacing.lg }}>
            <MarkdownBody source={query.data.body} />
            {query.data.updated_at ? (
              <HText variant="caption" tone="muted" style={{ marginTop: spacing.md }}>
                {formatDate(query.data.updated_at)} 갱신
              </HText>
            ) : null}
          </HandolCard>
        )
      }
    </SupportFrame>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.md, gap: spacing.sm },
  divider: { borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: colors.border },
});
