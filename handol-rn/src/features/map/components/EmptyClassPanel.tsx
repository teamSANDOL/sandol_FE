import { useEffect, useRef, useState } from 'react';
import { ScrollView, StyleSheet, TextInput, View, type ScrollViewInstance } from 'react-native';
import {
  ErrorRetryView,
  HPressable,
  HText,
  Icon,
  LoadingIndicator,
  colors,
  metrics,
  radius,
  spacing,
  typography,
} from '@/design-system';
import { ClassroomTimeSheet } from '@/features/empty_class/components/ClassroomTimeSheet';
import { MaterialIcon } from '@/features/empty_class/components/MaterialIcon';
import { useEmptyClasses, useRetryEmptyClasses } from '@/features/empty_class/hooks';
import { allPeriods, classPeriods, periodLabelOf, type ClassPeriod } from '@/features/empty_class/periods';
import { dayName, isToday, timeLabel } from '@/features/empty_class/query';
import { classroomQueryActions, useClassroomQuery } from '@/features/empty_class/queryStore';
import type { EmptyClass } from '@/features/empty_class/model';
import { ROOM_SORT_LABEL, ROOM_STATUSES, ROOM_STATUS_LABEL, visibleRows, type RoomSort } from '../roomStatus';
import { MapColors } from '../theme';
import { PopupMenu, type PopupOption } from './PopupMenu';
import { BuildingRoomsCard, StatusDot } from './RoomCards';

interface Props {
  /** 이 건물 카드로 스크롤한다 */
  focusBuilding: string | null;
  onBack: () => void;
  onBuildingPress: (b: EmptyClass) => void;
}

const SORT_OPTIONS: PopupOption<RoomSort>[] = (['building', 'count'] as const).map((s) => ({ label: ROOM_SORT_LABEL[s], value: s }));
const PERIOD_OPTIONS: PopupOption<ClassPeriod>[] = [
  { label: '전체 교시', value: allPeriods },
  ...classPeriods.map((p, i) => ({ label: `${i + 1}교시`, value: p })),
];

/**
 * '빈 강의실 현황' 시트 (Figma '맵- 빈강의실 버튼을 누를 시' 2538:17489). 조회 시간(지금 · 시간 선택) ·
 * 교시 선택 · 강의실 검색 · 정렬 · 범례 · 건물별 호실 상태 카드.
 */
export function EmptyClassPanel({ focusBuilding, onBack, onBuildingPress }: Props) {
  const classes = useEmptyClasses();
  const retry = useRetryEmptyClasses();
  const query = useClassroomQuery();
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState<RoomSort>('building');
  const [sortOpen, setSortOpen] = useState(false);
  const scroll = useRef<ScrollViewInstance>(null);
  const cardY = useRef<Record<string, number>>({});

  const items = classes.data;
  const total = items?.reduce((s, e) => s + e.emptyCount, 0) ?? 0;
  const rows = items ? visibleRows(items, search, sort) : null;

  const scrollToFocus = (name: string | null) => {
    const y = name ? cardY.current[name] : undefined;
    if (y !== undefined) scroll.current?.scrollTo({ y: Math.max(y, 0), animated: true }); // Flutter ensureVisible(alignment 0)
  };
  useEffect(() => scrollToFocus(focusBuilding), [focusBuilding, rows?.length]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <ScrollView ref={scroll} nestedScrollEnabled keyboardShouldPersistTaps="handled" contentContainerStyle={styles.content}>
      <View style={styles.titleRow}>
        <HPressable accessibilityRole="button" accessibilityLabel="뒤로" hitSlop={8} borderless onPress={onBack} style={styles.back}>
          <Icon name="backArrow" />
        </HPressable>
        <HText variant="headline" weight="bold" style={{ flex: 1 }}>
          빈 강의실 현황
        </HText>
        <HText variant="caption" tone="muted">
          총 {total}개
        </HText>
      </View>
      <View style={{ height: spacing.xs }} />
      <HText variant="body">
        {dayName(query)} {timeLabel(query)} 동안 비어있는 강의실
      </HText>
      <View style={{ height: spacing.md }} />
      <QueryCard search={search} onSearch={setSearch} />
      <View style={{ height: spacing.md }} />
      <View style={styles.legend}>
        {ROOM_STATUSES.map((s) => (
          <View key={s} style={styles.legendItem}>
            <StatusDot status={s} size={12} />
            <View style={{ width: spacing.xs }} />
            <HText variant="caption">{ROOM_STATUS_LABEL[s]}</HText>
          </View>
        ))}
        <View style={{ flex: 1 }} />
        <Pill label={ROOM_SORT_LABEL[sort]} trailing onPress={() => setSortOpen(true)} />
      </View>
      <PopupMenu visible={sortOpen} options={SORT_OPTIONS} onSelect={setSort} onClose={() => setSortOpen(false)} />
      <View style={{ height: spacing.md }} />
      {rows === null ? (
        classes.isError ? (
          <View style={{ height: 240 }}>
            <ErrorRetryView title="빈 강의실 정보를 불러오지 못했어요" onRetry={retry} />
          </View>
        ) : (
          <View style={styles.loading}>
            <LoadingIndicator />
          </View>
        )
      ) : (
        <>
          {rows.map((r) => (
            <View
              key={r.building.className}
              style={{ marginBottom: spacing.md }}
              onLayout={(e) => {
                cardY.current[r.building.className] = e.nativeEvent.layout.y;
                if (r.building.className === focusBuilding) scrollToFocus(focusBuilding);
              }}
            >
              <BuildingRoomsCard rows={r} onPress={() => onBuildingPress(r.building)} />
            </View>
          ))}
          {rows.length === 0 ? (
            <View style={{ padding: spacing.lg, alignItems: 'center' }}>
              <HText variant="caption" tone="muted">
                {search ? '검색 결과가 없어요' : '현재 빈 강의실이 없습니다.'}
              </HText>
            </View>
          ) : null}
        </>
      )}
    </ScrollView>
  );
}

/** 조회 시간 · 교시 선택 · 강의실 검색 카드 (2538:17489 Frame 2147235294) */
function QueryCard({ search, onSearch }: { search: string; onSearch: (s: string) => void }) {
  const query = useClassroomQuery();
  const [timeOpen, setTimeOpen] = useState(false);
  const [periodOpen, setPeriodOpen] = useState(false);
  const [focused, setFocused] = useState(false);
  const period = periodLabelOf(query.startMinutes, query.endMinutes);
  const isNow = isToday(query) && query.startMinutes === query.anchorMinutes && period === null;
  return (
    <View style={styles.queryCard}>
      <View style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
        <View style={{ flex: 1 }}>
          <HText variant="caption" tone="muted">
            조회 시간
          </HText>
          <View style={{ height: 9 }} />
          <View style={styles.pills}>
            <Pill label="지금 (현재)" icon="schedule" selected={isNow} onPress={classroomQueryActions.resetToNow} />
            <Pill label="시간 선택" selected={!isNow && period === null} onPress={() => setTimeOpen(true)} />
          </View>
        </View>
        <View style={styles.vline} />
        <View>
          <HText variant="caption" tone="muted">
            교시 선택
          </HText>
          <View style={{ height: 9 }} />
          <Pill label={period ?? '교시'} selected={period !== null} trailing onPress={() => setPeriodOpen(true)} />
        </View>
      </View>
      <View style={{ height: 12 }} />
      <View style={[styles.search, { borderColor: focused ? colors.primary : MapColors.line }]}>
        <MaterialIcon name="search" size={20} color={colors.primary} />
        <TextInput
          value={search}
          onChangeText={onSearch}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          placeholder="강의실을 검색하세요"
          placeholderTextColor={colors.muted}
          accessibilityLabel="강의실 검색"
          style={styles.input}
        />
      </View>
      <ClassroomTimeSheet visible={timeOpen} onClose={() => setTimeOpen(false)} />
      <PopupMenu
        visible={periodOpen}
        options={PERIOD_OPTIONS}
        onSelect={(p) => classroomQueryActions.setRange(p.start, p.end)}
        onClose={() => setPeriodOpen(false)}
      />
    </View>
  );
}

/** 알약 버튼. 고르면 primary 바탕. */
function Pill({
  label,
  icon,
  selected = false,
  trailing = false,
  onPress,
}: {
  label: string;
  icon?: 'schedule';
  selected?: boolean;
  trailing?: boolean;
  onPress: () => void;
}) {
  const fg = selected ? colors.background : colors.text;
  return (
    <View style={styles.pillClip}>
      <HPressable
        accessibilityRole="button"
        accessibilityState={{ selected }}
        onPress={onPress}
        style={[styles.pill, { backgroundColor: selected ? colors.primary : colors.background }]}
      >
        {icon ? <MaterialIcon name={icon} size={13} color={fg} /> : null}
        <HText variant="caption" style={{ color: fg }}>
          {label}
        </HText>
        {trailing ? <MaterialIcon name="keyboardArrowDown" size={16} color={fg} /> : null}
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: metrics.pageGutter, paddingTop: spacing.sm, paddingBottom: spacing.xl },
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  /** IconButton + VisualDensity.compact = 40x40 */
  back: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  legend: { flexDirection: 'row', alignItems: 'center' },
  legendItem: { flexDirection: 'row', alignItems: 'center', marginRight: 20 },
  loading: { padding: spacing.xl, alignItems: 'center' },
  queryCard: {
    paddingTop: 18,
    paddingHorizontal: 20,
    paddingBottom: 10,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: MapColors.line,
    backgroundColor: colors.white,
  },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  vline: { width: 1, height: 37, marginLeft: 10, marginRight: 10, marginTop: 22, backgroundColor: MapColors.line },
  search: { height: 44, flexDirection: 'row', alignItems: 'center', paddingLeft: 12, borderRadius: radius.md, borderWidth: 1 },
  input: { ...typography.caption, flex: 1, height: 44, paddingVertical: 0, paddingHorizontal: 8 },
  // 높이 고정 대신 세로 여백으로 30을 맞춰 글꼴이 커지면 함께 늘어난다.
  pillClip: { borderRadius: 30, overflow: 'hidden' },
  pill: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs, paddingHorizontal: 12, paddingVertical: 7, borderRadius: 30, borderWidth: 1, borderColor: MapColors.line },
});
