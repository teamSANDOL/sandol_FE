import { StyleSheet, TextInput, View } from 'react-native';
import { HPressable, HText, colors, metrics, radius, spacing, typography } from '@/design-system';
import { NOTICE_FILTERS, type NoticeFilter } from '../model';
import { ArrowDropDownIcon, BookmarkBorderIcon, CloseIcon, SearchIcon, TuneIcon } from './NoticeIcons';

const CHIP_GAP = 7;
const CHIPS_PER_ROW = 4;

/** 검색창 (Figma Frame 2147234866): 돋보기 · 힌트 · 오른쪽 필터 아이콘. 입력이 있으면 지우기 버튼. */
export function SearchBox({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <View style={styles.search}>
      <View style={styles.searchIcon}>
        <SearchIcon size={metrics.iconSize} color={colors.primary} />
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
          <TuneIcon size={20} color={colors.muted} />
        ) : (
          <HPressable accessibilityRole="button" accessibilityLabel="검색어 지우기" onPress={() => onChange('')} borderless style={styles.clear}>
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
        accessibilityState={{ selected: isSelected }}
        onPress={onPress}
        style={[styles.chip, isSelected ? { backgroundColor: colors.primary, borderColor: colors.primary } : { backgroundColor: colors.background, borderColor: colors.border }]}
      >
        {isSaved && <BookmarkBorderIcon size={14} color={isSelected ? colors.background : colors.text} />}
        <HText variant="caption" tone={isSelected ? 'onPrimary' : undefined} numberOfLines={1} adjustsFontSizeToFit>
          {label}
        </HText>
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
        <ArrowDropDownIcon size={20} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  search: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.background, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border },
  searchIcon: { paddingHorizontal: 11 },
  input: { ...typography.caption, flex: 1, paddingVertical: 17, lineHeight: undefined },
  searchTail: { width: 44, alignItems: 'center', justifyContent: 'center' },
  clear: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  chipRow: { flexDirection: 'row', gap: CHIP_GAP },
  chipClip: { flex: 1, borderRadius: radius.md, overflow: 'hidden' },
  chip: { minHeight: 32, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.xs, borderWidth: 1, borderRadius: radius.md, paddingHorizontal: 4 },
  summary: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.sm },
  summaryTitle: { flex: 1, flexDirection: 'row', flexWrap: 'wrap', columnGap: spacing.sm, alignItems: 'center' },
  sort: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.background, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border, paddingLeft: 10, paddingRight: 6, paddingVertical: 8 },
});
