import { FlatList, StyleSheet, View } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { AppTopBar, ErrorRetryView, HText, LoadingIndicator, MaterialIcon, colors, legacyColors } from '@/design-system';
import { OrganizationSearchResultCard } from '../components/OrganizationSearchResultCard';
import { useOrganizationSearch } from '../hooks';

/** 조직도 검색 결과 (/home/organization/search?query=) */
export default function OrganizationSearchScreen() {
  const { query: raw } = useLocalSearchParams<{ query?: string | string[] }>();
  const query = (Array.isArray(raw) ? raw[0] : raw) ?? '';
  const search = useOrganizationSearch(query);

  return (
    <View style={styles.root}>
      <AppTopBar
        title={`"${query}" 검색 결과`}
        titleNode={
          <HText legacy="title03" numberOfLines={1}>
            {`"${query}" 검색 결과`}
          </HText>
        }
        onBack={() => router.back()}
        showUser={false}
        backgroundColor={colors.white}
        style={styles.bar}
      />
      {search.isPending ? (
        <View style={styles.center}>
          <LoadingIndicator />
        </View>
      ) : search.isError ? (
        <ErrorRetryView title="검색 결과를 불러오지 못했어요" onRetry={() => void search.refetch()} />
      ) : (
        <FlatList
          data={search.results}
          keyExtractor={(_, i) => String(i)}
          contentContainerStyle={{ paddingHorizontal: 12, paddingVertical: 8, flexGrow: 1 }}
          ItemSeparatorComponent={() => <View style={styles.divider} />}
          ListEmptyComponent={<Empty />}
          renderItem={({ item }) => <OrganizationSearchResultCard result={item} />}
        />
      )}
    </View>
  );
}

function Empty() {
  return (
    <View style={styles.center}>
      <MaterialIcon name="searchOff" size={48} color={legacyColors.textMuted} />
      <View style={{ height: 12 }} />
      <HText legacy="body" style={{ color: legacyColors.textMuted }}>
        검색 결과가 없습니다.
      </HText>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: legacyColors.background },
  bar: { borderBottomWidth: 0.5, borderBottomColor: colors.border },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  divider: { height: 1, backgroundColor: legacyColors.cardBorder },
});
