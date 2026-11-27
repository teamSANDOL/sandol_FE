import { StyleSheet, View } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTopBar, GradientScrollView, HandolCard, HPressable, HText, LoadingIndicator, colors, metrics, spacing } from '@/design-system';
import { openExternalLink } from '@/core/utils/externalLink';
import { usePolicy } from '../policyApi';
import { POLICY_DOCS, toPolicyDocId } from '../policyDocs';
import { DocBlocks } from '../components/DocBlocks';

/** 서비스 이용약관 · 개인정보처리방침을 앱 안에서 보여 준다. */
export default function PolicyScreen() {
  const { doc: rawDoc } = useLocalSearchParams<{ doc?: string | string[] }>();
  const doc = toPolicyDocId(rawDoc);
  const { label, url } = POLICY_DOCS[doc];
  const policy = usePolicy(doc);
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar
        title={label}
        titleNode={<HText variant="title">{label}</HText>}
        onBack={() => router.back()}
        showUser={false}
        horizontalPadding={metrics.pageGutter - 10}
      />
      {policy.data ? (
        <GradientScrollView
          contentContainerStyle={{
            paddingHorizontal: metrics.pageGutter,
            paddingTop: spacing.md,
            paddingBottom: spacing.xl + insets.bottom,
          }}
        >
          {policy.data.intro ? (
            <HText variant="body" tone="muted" keepAll style={{ marginBottom: spacing.md }}>
              {policy.data.intro}
            </HText>
          ) : null}
          <HandolCard
            contentStyle={{
              paddingHorizontal: metrics.cardInset,
              paddingTop: spacing.sm,
              paddingBottom: spacing.lg,
            }}
          >
            <DocBlocks blocks={policy.data.blocks} />
          </HandolCard>
        </GradientScrollView>
      ) : policy.isError ? (
        <ErrorView onRetry={() => void policy.refetch()} onOpenWeb={() => void openExternalLink(url)} />
      ) : (
        <View style={styles.center}>
          <LoadingIndicator />
        </View>
      )}
    </View>
  );
}

function ErrorView({ onRetry, onOpenWeb }: { onRetry: () => void; onOpenWeb: () => void }) {
  return (
    <View style={[styles.center, { padding: metrics.pageGutter, gap: spacing.sm }]}>
      <HText variant="body" tone="muted" keepAll>
        문서를 불러오지 못했어요.
      </HText>
      <HPressable accessibilityRole="button" onPress={onRetry} style={styles.textBtn}>
        <HText variant="caption" tone="accent">
          다시 시도
        </HText>
      </HPressable>
      <HPressable accessibilityRole="link" onPress={onOpenWeb} style={styles.textBtn}>
        <HText variant="caption" tone="muted">
          웹에서 보기
        </HText>
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  textBtn: { paddingHorizontal: 16, paddingVertical: 10 },
});
