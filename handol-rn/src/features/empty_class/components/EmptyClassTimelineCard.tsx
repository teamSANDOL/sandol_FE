import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated from 'react-native-reanimated';
import { HPressable, HText, HandolCard, HandolNote, LoadingIndicator, metrics, radius, spacing } from '@/design-system';
import { useNearbyEmptyClasses, useRetryEmptyClasses } from '../hooks';
import { dayShort, isAfterClassDay, isWeekend, timeLabel, type ClassroomQuery } from '../query';
import { classroomQueryActions, useClassroomQuery } from '../queryStore';
import { walkMinutes, type BuildingSort, type NearbyEmptyClass } from '../sort';
import { useBuildingSortSettings } from '../sortStore';
import { ClassroomTimeRangePicker } from './ClassroomTimeRangePicker';

/** 건물당 미리 보여줄 호실 수. 나머지는 `+N` */
const PREVIEW_ROOMS = 3;
/** 다시 불러오는 동안 목록 흐림 (AnimatedOpacity 150ms) */
const DIM_OPACITY = 0.55;
const DIM_FADE_MS = 150;

interface Props {
  maxItems?: number;
  /** 건물 행을 눌렀을 때. 건물명(예: `E동`)을 넘긴다. */
  onBuildingPress?: (buildingName: string) => void;
}

/**
 * 홈의 빈 강의실 카드 (Figma 2153:303). 지금부터 마지막 교시 끝(22:30)까지를 교시 시각 축으로 두고
 * 두 손잡이로 공강 구간을 잡으면, 그 구간 내내 비어 있는 강의실을 가까운 건물 순으로 보여준다.
 */
export function EmptyClassTimelineCard({ maxItems = 3, onBuildingPress }: Props) {
  const query = useClassroomQuery();
  const sortMode = useBuildingSortSettings().mode;
  const { items, isLoading, isError, isRefreshing } = useNearbyEmptyClasses();
  const retry = useRetryEmptyClasses();
  const [preview, setPreview] = useState<ClassroomQuery | null>(null);

  // 앱을 오래 켜 둔 뒤 돌아오면 구간 시작이 과거일 수 있다.
  useEffect(() => {
    classroomQueryActions.syncToNow();
  }, []);

  return (
    <HandolCard padding={0} contentStyle={styles.card}>
      <ClassroomTimeRangePicker onPreview={setPreview} />
      <View style={{ height: spacing.md }} />
      <Summary query={preview ?? query} items={items} refreshing={isRefreshing} />
      {isWeekend(query) || isAfterClassDay(query) ? (
        <View style={{ marginTop: spacing.sm }}>
          <HandolNote text="수업이 없는 시간이라 모든 강의실이 비어 있어요." />
        </View>
      ) : null}
      <View style={{ height: 14 }} />
      {isError ? (
        <ErrorRow onRetry={retry} />
      ) : isLoading || !items ? (
        <View style={styles.loading}>
          <LoadingIndicator />
        </View>
      ) : (
        <BuildingList
          items={items}
          maxItems={maxItems}
          dimmed={isRefreshing}
          sortMode={sortMode}
          onBuildingPress={onBuildingPress}
        />
      )}
    </HandolCard>
  );
}

/** 요약 한 줄: 요일 + 구간 · 빈 강의실 개수 */
function Summary({ query, items, refreshing }: { query: ClassroomQuery; items?: NearbyEmptyClass[]; refreshing: boolean }) {
  const total = items?.reduce((s, e) => s + e.building.emptyCount, 0);
  return (
    <View style={styles.summary}>
      <HText variant="body" style={{ flex: 1 }}>
        {dayShort(query)} {timeLabel(query)}
      </HText>
      <HText variant="body" weight="bold" tone={refreshing ? 'muted' : 'accent'}>
        빈 강의실 {total ?? '…'}곳
      </HText>
    </View>
  );
}

function BuildingList({
  items,
  maxItems,
  dimmed,
  sortMode,
  onBuildingPress,
}: {
  items: NearbyEmptyClass[];
  maxItems: number;
  dimmed: boolean;
  sortMode: BuildingSort;
  onBuildingPress?: (name: string) => void;
}) {
  const withRooms = items.filter((e) => e.building.emptyCount > 0).slice(0, maxItems);
  if (withRooms.length === 0) {
    return (
      <HText variant="caption" tone="muted">
        이 시간에 비어 있는 강의실이 없어요. 구간을 줄여 보세요.
      </HText>
    );
  }
  return (
    <Animated.View
      style={{ gap: 14, opacity: dimmed ? DIM_OPACITY : 1, transitionProperty: 'opacity', transitionDuration: DIM_FADE_MS, transitionTimingFunction: 'linear' }}
    >
      {withRooms.map((item) => (
        <BuildingRow key={item.building.className} item={item} showWalk={sortMode === 'distance'} onPress={onBuildingPress} />
      ))}
    </Animated.View>
  );
}

/** `TIP  도보 N분` / `0000호 0000호 000호 +NN` · 오른쪽 `NN곳` */
function BuildingRow({ item, showWalk, onPress }: { item: NearbyEmptyClass; showWalk: boolean; onPress?: (name: string) => void }) {
  const b = item.building;
  const walk = showWalk ? walkMinutes(item) : null;
  const preview = b.classList.slice(0, PREVIEW_ROOMS);
  const rest = b.classList.length - preview.length;
  const rooms = [...preview, ...(rest > 0 ? [`+${rest}`] : [])].join(' ');
  return (
    <View style={styles.rowClip}>
      <HPressable
        accessibilityRole="button"
        accessibilityLabel={`${b.className} 빈 강의실 ${b.emptyCount}곳`}
        disabled={!onPress}
        onPress={() => onPress?.(b.className)}
        style={styles.row}
      >
        <View style={{ flex: 1 }}>
          <View style={styles.nameRow}>
            <HText variant="body" weight="bold" tone="accent">
              {b.className}
            </HText>
            {walk !== null ? <HText variant="caption">도보 {walk}분</HText> : null}
          </View>
          {rooms ? (
            <HText variant="caption" tone="muted" numberOfLines={1}>
              {rooms}
            </HText>
          ) : null}
        </View>
        <HText variant="caption" style={{ marginLeft: spacing.sm }}>
          {b.emptyCount}곳
        </HText>
      </HPressable>
    </View>
  );
}

function ErrorRow({ onRetry }: { onRetry: () => void }) {
  return (
    <View style={styles.summary}>
      <HText variant="caption" tone="muted" style={{ flex: 1 }}>
        빈 강의실 정보를 불러올 수 없습니다.
      </HText>
      <HPressable accessibilityRole="button" onPress={onRetry} style={styles.retry}>
        <HText variant="caption" tone="accent">
          다시 시도
        </HText>
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { paddingHorizontal: metrics.cardInset, paddingVertical: 12 },
  summary: { flexDirection: 'row', alignItems: 'center' },
  loading: { paddingVertical: 18, alignItems: 'center' },
  // Flutter InkWell 은 내용을 자르지 않는다. 자르면 굵은 'B' 처럼 왼쪽으로 삐져나온 글자가 잘린다.
  rowClip: { borderRadius: radius.md },
  row: { flexDirection: 'row', alignItems: 'center' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  retry: { paddingHorizontal: 12, paddingVertical: 8 },
});
