import { StyleSheet, View } from 'react-native';
import { HPressable, HText, Icon, colors, radius, spacing } from '@/design-system';
import { MaterialIcon } from '@/features/empty_class/components/MaterialIcon';
import { groupByFloor, ROOM_STATUS_LABEL, type BuildingRows, type RoomRow, type RoomStatus } from '../roomStatus';
import { MapColors } from '../theme';

const STATUS_STYLE: Record<RoomStatus, { fill: string; dot: string }> = {
  empty: { fill: MapColors.soft, dot: colors.primary },
  busy: { fill: MapColors.busy, dot: MapColors.busyDot },
};

export function StatusDot({ status, size }: { status: RoomStatus; size: number }) {
  return <View style={{ width: size, height: size, borderRadius: size / 2, backgroundColor: STATUS_STYLE[status].dot }} />;
}

/** 건물 한 장: 건물명 · 빈 개수 · 층별 호실 상태 칩 (2538:17489 Frame 2147235306) */
export function BuildingRoomsCard({ rows, onPress }: { rows: BuildingRows; onPress: () => void }) {
  const { building, rooms } = rows;
  return (
    <View style={styles.card}>
      <View style={styles.headClip}>
        <HPressable accessibilityRole="button" accessibilityLabel={`${building.className} 상세`} onPress={onPress} style={styles.head}>
          <HText variant="headline" weight="bold" tone="accent" style={{ flex: 1 }}>
            {building.className}
          </HText>
          <HText variant="body" weight="bold" tone="accent">
            {building.emptyCount}개
          </HText>
          <View style={{ width: spacing.md }} />
          <MaterialIcon name="chevronRight" size={20} color={colors.text} />
        </HPressable>
      </View>
      {groupByFloor(rooms).map((g, i) => (
        <View key={g.floor}>
          {/* 건물명 아래 9, 층 사이 16 (Figma 2:5784 ~ 2:5789, 2:5796) */}
          <View style={{ height: i === 0 ? 9 : 16 }} />
          <View style={styles.floorRow}>
            <Icon name="floor" width={12} />
            <HText variant="caption">{g.floor}</HText>
          </View>
          <View style={{ height: spacing.sm }} />
          <View style={styles.chips}>
            {g.rooms.map((r) => (
              <RoomChip key={r.room} row={r} />
            ))}
          </View>
        </View>
      ))}
    </View>
  );
}

function RoomChip({ row }: { row: RoomRow }) {
  return (
    <View style={[styles.chip, { backgroundColor: STATUS_STYLE[row.status].fill }]}>
      <HText variant="caption">{row.room}</HText>
      <View style={{ height: 4 }} />
      <View style={styles.statusRow}>
        <StatusDot status={row.status} size={7} />
        <HText variant="caption" style={styles.statusLabel}>
          {ROOM_STATUS_LABEL[row.status]}
        </HText>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: radius.md, borderWidth: 1, borderColor: MapColors.line, paddingLeft: 20, paddingRight: 20, paddingTop: 9, paddingBottom: 16 },
  headClip: { borderRadius: radius.md, overflow: 'hidden' },
  head: { flexDirection: 'row', alignItems: 'center' },
  floorRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 4 },
  chip: {
    minWidth: 58,
    height: 51,
    paddingHorizontal: 7,
    justifyContent: 'center',
    alignItems: 'flex-start',
    borderRadius: 10.9,
    borderWidth: 1,
    borderColor: MapColors.line,
  },
  statusRow: { flexDirection: 'row', alignItems: 'center', gap: 2.4 },
  statusLabel: { fontSize: 10, lineHeight: 10 },
});
