import { useEffect, useRef, useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
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
import { SheetScrollView, useSheetScrollTo } from './SheetScrollView';

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
  const scrollTo = useSheetScrollTo();
  const cardY = useRef<Record<string, number>>({});

  const items = classes.data;
  const total = items?.reduce((s, e) => s + e.emptyCount, 0) ?? 0;
  const rows = items ? visibleRows(items, search, sort) : null;

  const scrollToFocus = (name: string | null) => {
    const y = name ? cardY.current[name] : undefined;
    if (y !== undefined) scrollTo?.(y); // Flutter ensureVisible(alignment 0, 300ms easeOut)
  };
  useEffect(() => scrollToFocus(focusBuilding), [focusBuilding, rows?.length]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <SheetScrollView nestedScrollEnabled keyboardShouldPersistTaps="handled" contentContainerStyle={styles.content}>
      {/* 제목 22 + 8 + 부제 16, 총 N개는 아래 맞춤 (Figma 2:5741) */}
      <View style={styles.header}>
        <View style={{ flex: 1 }}>
          <View style={styles.titleRow}>
            <HPressable accessibilityRole="button" accessibilityLabel="뒤로" hitSlop={10} borderless onPress={onBack} style={styles.back}>
              <Icon name="backArrow" />
            </HPressable>
            <HText variant="headline" weight="bold">
              빈 강의실 현황
            </HText>
          </View>
          <View style={{ height: spacing.sm }} />
          <HText variant="caption" tone="muted">
            {dayName(query)} {timeLabel(query)} 동안 비어있는 강의실
          </HText>
        </View>
        <HText variant="body" weight="bold" tone="accent" style={{ marginLeft: spacing.sm }}>
          총 {total}개
        </HText>
      </View>
      <View style={{ height: 18 }} />
      <QueryCard search={search} onSearch={setSearch} />
      <View style={{ height: 9 }} />
      <View style={styles.legend}>
        {ROOM_STATUSES.map((s) => (
          <View key={s} style={styles.legendItem}>
            <StatusDot status={s} size={12} />
            <View style={{ width: spacing.xs }} />
            <HText variant="caption">{ROOM_STATUS_LABEL[s]}</HText>
          </View>
        ))}
        <View style={{ flex: 1 }} />
        <Pill label={ROOM_SORT_LABEL[sort]} trailing minWidth={80} onPress={() => setSortOpen(true)} />
      </View>
      <PopupMenu visible={sortOpen} options={SORT_OPTIONS} onSelect={setSort} onClose={() => setSortOpen(false)} />
      {/* 정렬 알약 아래 302 → 목록 카드 330 (Figma 2:5769, 2:5783) */}
      <View style={{ height: 28 }} />
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
    </SheetScrollView>
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
        <MaterialIcon name="search" size={21} color={colors.primary} />
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
  minWidth = 90,
  onPress,
}: {
  label: string;
  icon?: 'schedule';
  selected?: boolean;
  trailing?: boolean;
  /** Figma 알약은 90x30 (정렬은 80x30) */
  minWidth?: number;
  onPress: () => void;
}) {
  const fg = selected ? colors.background : colors.text;
  return (
    <View style={styles.pillClip}>
      <HPressable
        accessibilityRole="button"
        accessibilityState={{ selected }}
        onPress={onPress}
        style={[styles.pill, { minWidth, backgroundColor: selected ? colors.primary : colors.background }]}
      >
        {icon ? <MaterialIcon name={icon} size={13} color={fg} /> : null}
        <HText variant="caption" style={{ color: fg }}>
          {label}
        </HText>
        {trailing ? <MaterialIcon name="keyboardArrowDown" size={14} color={fg} /> : null}
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  // 시트 안 제목 윗선 56 (Figma 2:5741), 손잡이 영역 18 + 테두리 1 을 뺀 값
  content: { paddingHorizontal: metrics.pageGutter, paddingTop: 37, paddingBottom: spacing.xl },
  header: { flexDirection: 'row', alignItems: 'flex-end' },
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  // 뒤로 버튼은 시안에 없는 기능 진입점. 제목 줄 높이 22 를 넘지 않게 두고 눌리는 영역만 hitSlop 으로 넓힌다.
  back: { width: 32, height: 22, justifyContent: 'center' },
  legend: { flexDirection: 'row', alignItems: 'center' },
  legendItem: { flexDirection: 'row', alignItems: 'center', marginRight: 20 },
  loading: { padding: spacing.xl, alignItems: 'center' },
  queryCard: {
    paddingTop: 18,
    paddingHorizontal: 22,
    paddingBottom: 10,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: MapColors.line,
    backgroundColor: colors.white,
  },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  vline: { width: 1, height: 37, marginLeft: 12, marginRight: 11, marginTop: 22, backgroundColor: MapColors.line },
  // 돋보기 21 x9.6, 글 x40 (Figma 2:5764, 2:5768: 글 12.2/14)
  search: { height: 44.5, flexDirection: 'row', alignItems: 'center', paddingLeft: 9, borderRadius: radius.md, borderWidth: 1 },
  input: { ...typography.caption, fontSize: 12.2, lineHeight: 14, flex: 1, height: 44, paddingVertical: 0, paddingLeft: 0, paddingRight: 8, marginLeft: 9 },
  // 높이 고정 대신 세로 여백으로 30을 맞춰 글꼴이 커지면 함께 늘어난다.
  pillClip: { borderRadius: 30, overflow: 'hidden' },
  pill: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs, justifyContent: 'center', paddingHorizontal: 11, paddingVertical: 6, borderRadius: 30, borderWidth: 1, borderColor: MapColors.line },
});
