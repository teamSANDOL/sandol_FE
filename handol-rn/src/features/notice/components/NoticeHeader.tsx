import { StyleSheet, TextInput, View } from 'react-native';
import { HPressable, HText, colors, metrics, radius, spacing, typography } from '@/design-system';
import { NOTICE_FILTERS, type NoticeFilter } from '../model';
import { BookmarkBorderIcon, ChevronDownIcon, CloseIcon, SearchIcon, TuneIcon } from './NoticeIcons';

const CHIP_GAP = 7;
const CHIPS_PER_ROW = 4;
/** 아이콘 글리프가 Figma 20 이 되도록 24 상자 안 그림을 키운다 (2:6057 · 2:6061) */
const SEARCH_ICON = 28;
const TUNE_ICON = 26;

/** 검색창 (Figma Frame 2147234866): 돋보기 · 힌트 · 오른쪽 필터 아이콘. 입력이 있으면 지우기 버튼. */
export function SearchBox({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <View style={styles.search}>
      <View style={styles.searchIcon}>
        <SearchIcon size={SEARCH_ICON} color={colors.primary} />
      </View>
      <TextInput
        value={value}
        onChangeText={onChange}
        returnKeyType="search"
        placeholder="어떤 공지를 찾고 있나요?"
        placeholderTextColor={colors.muted}
        style={styles.input}
        accessibilityLabel="공지 검색"
      />
      <View style={styles.searchTail}>
        {value === '' ? (
          <TuneIcon size={TUNE_ICON} color={colors.muted} />
        ) : (
          <HPressable accessibilityRole="button" accessibilityLabel="검색어 지우기" onPress={() => onChange('')} borderless hitSlop={12} style={styles.clear}>
            <CloseIcon size={20} color={colors.muted} />
          </HPressable>
        )}
      </View>
    </View>
  );
}

function FilterChip({ label, isSelected, isSaved, onPress }: { label: string; isSelected: boolean; isSaved: boolean; onPress: () => void }) {
  return (
    <View style={styles.chipClip}>
      <HPressable
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityState={{ selected: isSelected }}
        onPress={onPress}
        style={[styles.chip, isSelected ? { backgroundColor: colors.primary, borderColor: colors.primary } : { backgroundColor: colors.background, borderColor: colors.border }]}
      >
        {/* 시안의 '저장한 공지' 칸은 글자 없이 북마크 아이콘만 있다 (Figma 2:6091) */}
        {isSaved ? (
          <BookmarkBorderIcon size={14} color={isSelected ? colors.background : colors.text} />
        ) : (
          <HText variant="caption" weight={isSelected ? 'bold' : undefined} tone={isSelected ? 'onPrimary' : undefined} numberOfLines={1} adjustsFontSizeToFit>
            {label}
          </HText>
        )}
      </HPressable>
    </View>
  );
}

/** 분류 칩 줄 (Figma Frame 2147235232): 한 줄 4개, 칸 사이 7 · 줄 사이 8. */
export function FilterChips({ selected, onSelect }: { selected: NoticeFilter; onSelect: (f: NoticeFilter) => void }) {
  const rows: Array<typeof NOTICE_FILTERS[number][]> = [];
  for (let i = 0; i < NOTICE_FILTERS.length; i += CHIPS_PER_ROW) rows.push(NOTICE_FILTERS.slice(i, i + CHIPS_PER_ROW));
  return (
    <View style={{ gap: spacing.sm }}>
      {rows.map((row) => (
        <View key={row[0].key} style={styles.chipRow}>
          {row.map((f) => (
            <FilterChip key={f.key} label={f.label} isSelected={f.key === selected} isSaved={f.key === 'saved'} onPress={() => onSelect(f.key)} />
          ))}
        </View>
      ))}
    </View>
  );
}

/** '최신 공지  총 N건' 과 오른쪽 '최신순' 표시 (Figma Frame 2147235230). API 가 최신순만 줘서 누를 수 없다. */
export function SummaryRow({ total }: { total: number }) {
  return (
    <View style={styles.summary}>
      <View style={styles.summaryTitle}>
        <HText variant="headline" weight="bold">
          최신 공지
        </HText>
        <HText variant="caption" tone="muted">
          {`총 ${total}건`}
        </HText>
      </View>
      <View style={styles.sort}>
        <HText variant="caption">최신순</HText>
        <ChevronDownIcon />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  // Figma 2:6056: 높이 51, 돋보기 24 (왼쪽 11, 힌트까지 11), 오른쪽 필터 20 (끝에서 13)
  search: { flexDirection: 'row', alignItems: 'center', height: 51, backgroundColor: colors.background, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border },
  searchIcon: { paddingHorizontal: 9 },
  input: { ...typography.caption, flex: 1, paddingVertical: 0, paddingHorizontal: 0 },
  searchTail: { width: 20, height: 20, marginRight: 13, alignItems: 'center', justifyContent: 'center' },
  clear: { width: 20, height: 20, alignItems: 'center', justifyContent: 'center' },
  chipRow: { flexDirection: 'row', gap: CHIP_GAP },
  chipClip: { flex: 1, borderRadius: radius.md, overflow: 'hidden' },
  chip: { minHeight: 32, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.xs, borderWidth: 1, borderRadius: radius.md, paddingHorizontal: 10, paddingVertical: 4 },
  // Figma 2:6093: 줄 높이 42, 제목 왼쪽 안쪽 6, 정렬 칸 81x32 은 내용 오른쪽 끝보다 6 더 나간다
  summary: { flexDirection: 'row', alignItems: 'center', minHeight: 42, marginRight: -6, marginBottom: spacing.sm },
  summaryTitle: { flex: 1, flexDirection: 'row', flexWrap: 'wrap', columnGap: spacing.sm, alignItems: 'center', paddingLeft: 6 },
  sort: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, height: 32, paddingHorizontal: 10, backgroundColor: colors.background, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border },
});
