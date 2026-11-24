import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
import { router } from 'expo-router';
import {
  AppTopBar,
  ErrorRetryView,
  GradientScrollView,
  HandolCard,
  HText,
  Icon,
  LoadingIndicator,
  colors,
  metrics,
  spacing,
  typography,
} from '@/design-system';
import { OrganizationNodeCard } from '../components/OrganizationNodeCard';
import { OrganizationSearchResultCard } from '../components/OrganizationSearchResultCard';
import { useOrganizationTree } from '../hooks';
import { searchOrganizationTree, type OrganizationGroup } from '../model';

/** 시안 Frame 2147234888 의 모서리 */
const CARD_RADIUS = 16;
const CARD_PADDING = { paddingHorizontal: metrics.cardInset, paddingVertical: 32 } as const;

/**
 * 학과/부서 조직도 (Figma 2158:882).
 * 검색창 아래 카드 하나에 트리를 담는다. 검색어가 있으면 트리 대신 같은 카드에 부분일치 결과를 보여준다.
 */
export default function OrganizationTreeScreen() {
  const [query, setQuery] = useState('');
  const tree = useOrganizationTree();
  const q = query.trim();

  return (
    <View style={styles.root}>
      <AppTopBar
        title="학과/부서 조직도"
        titleNode={<HText variant="title">학과/부서 조직도</HText>}
        onBack={() => router.back()}
        horizontalPadding={metrics.pageGutter - 10}
      />
      <GradientScrollView
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        onRefresh={() => void tree.refetch()}
        isRefreshing={tree.isRefetching}
        contentContainerStyle={styles.content}
      >
        <SearchField value={query} onChange={setQuery} />
        <View style={{ height: 21 }} />
        {tree.isPending ? (
          <View style={{ paddingTop: 60, alignItems: 'center' }}>
            <LoadingIndicator />
          </View>
        ) : tree.isError || !tree.data ? (
          <ErrorRetryView title="조직도를 불러오지 못했어요" onRetry={() => void tree.refetch()} />
        ) : q ? (
          <SearchResultCard root={tree.data} query={q} />
        ) : (
          <TreeCard root={tree.data} />
        )}
      </GradientScrollView>
    </View>
  );
}

/** 돋보기 + 입력칸 (2158:884) */
function SearchField({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <HandolCard contentStyle={styles.searchCard}>
      <Icon name="orgSearch" />
      <TextInput
        value={value}
        onChangeText={onChange}
        style={styles.input}
        placeholder="학과 또는 부서 이름 검색"
        placeholderTextColor={colors.muted}
        returnKeyType="search"
        autoCorrect={false}
        accessibilityLabel="학과 또는 부서 이름 검색"
      />
    </HandolCard>
  );
}

/** 최상위 부서(대표연락처)와 그룹 목록 (2158:891) */
function TreeCard({ root }: { root: OrganizationGroup }) {
  const units = root.children.filter((c) => c.kind === 'unit');
  const groups = root.children.filter((c) => c.kind === 'group');
  return (
    <HandolCard borderRadius={CARD_RADIUS} contentStyle={[CARD_PADDING, { gap: 32 }]}>
      {units.map((u, i) => (
        <OrganizationNodeCard key={`${u.name}-${i}`} node={u} />
      ))}
      {groups.length > 0 && (
        <View>
          {groups.map((g, i) => (
            <OrganizationNodeCard key={`${g.name}-${i}`} node={g} />
          ))}
        </View>
      )}
    </HandolCard>
  );
}

function SearchResultCard({ root, query }: { root: OrganizationGroup; query: string }) {
  const results = searchOrganizationTree(root, query);
  return (
    <HandolCard borderRadius={CARD_RADIUS} contentStyle={[CARD_PADDING, { gap: spacing.md }]}>
      {results.length === 0 ? (
        <HText variant="caption" tone="muted" style={{ textAlign: 'center' }}>
          검색 결과가 없습니다.
        </HText>
      ) : (
        results.map((r, i) => <OrganizationSearchResultCard key={i} result={r} />)
      )}
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background },
  content: { paddingHorizontal: metrics.pageGutter, paddingTop: spacing.sm, paddingBottom: spacing.xl },
  searchCard: { flexDirection: 'row', alignItems: 'center', gap: 11, paddingLeft: 10, paddingRight: metrics.cardInset, paddingVertical: 12 },
  input: { flex: 1, height: 24, padding: 0, textAlignVertical: 'center', fontFamily: typography.caption.fontFamily, fontSize: typography.caption.fontSize, color: colors.text },
});
