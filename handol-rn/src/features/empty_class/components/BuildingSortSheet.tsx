import { useRef, useState } from 'react';
import { PanResponder, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { HPressable, HText, colors, legacyColors, radius } from '@/design-system';
import { BUILDING_SORTS, BUILDING_SORT_LABELS, mergedOrder, moveItem, type BuildingSort } from '../sort';
import { useNearbyEmptyClasses } from '../hooks';
import { buildingSortActions, useBuildingSortSettings } from '../sortStore';
import { emptyClassTheme } from '../theme';
import { BottomSheet } from './BottomSheet';
import { MaterialIcon, type MaterialIconName } from './MaterialIcon';

const SORT_ICON: Record<BuildingSort, MaterialIconName> = {
  distance: 'myLocation',
  count: 'meetingRoom',
  custom: 'dragHandle',
};

/** 홈 빈 강의실 카드의 건물 정렬 설정 시트. 정렬 방식 선택 + 내 순서 편집. 변경은 즉시 저장된다. */
export function BuildingSortSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const settings = useBuildingSortSettings();
  const { items } = useNearbyEmptyClasses();
  const order = mergedOrder(settings, items?.map((e) => e.building.className) ?? []);
  return (
    <BottomSheet visible={visible} onClose={onClose}>
      <HText legacy="title03" style={{ color: emptyClassTheme.black87 }}>
        정렬 설정
      </HText>
      <View style={{ height: 10 }} />
      {BUILDING_SORTS.map((mode) => (
        <SortOption key={mode} mode={mode} selected={settings.mode === mode} />
      ))}
      {settings.mode === 'custom' ? (
        <View style={{ paddingTop: 6 }}>
          <ReorderList order={order} onReorder={(from, to) => buildingSortActions.setCustomOrder(moveItem(order, from, to))} />
        </View>
      ) : null}
    </BottomSheet>
  );
}

function SortOption({ mode, selected }: { mode: BuildingSort; selected: boolean }) {
  const tint = selected ? legacyColors.primary : legacyColors.textMuted;
  return (
    <View style={styles.optionClip}>
      <HPressable
        accessibilityRole="radio"
        accessibilityState={{ selected }}
        onPress={() => buildingSortActions.setMode(mode)}
        style={styles.option}
      >
        <MaterialIcon name={SORT_ICON[mode]} size={18} color={tint} />
        <HText legacy="caption01" style={{ flex: 1, color: selected ? legacyColors.primary : emptyClassTheme.black87 }}>
          {BUILDING_SORT_LABELS[mode]}
        </HText>
        <Radio selected={selected} />
      </HPressable>
    </View>
  );
}

function Radio({ selected }: { selected: boolean }) {
  const color = selected ? legacyColors.primary : emptyClassTheme.radioOff;
  return (
    <View style={[styles.radio, { borderColor: color }]}>
      {selected ? <View style={[styles.radioDot, { backgroundColor: color }]} /> : null}
    </View>
  );
}

/** 홈에 보이는 상위 RANKED_COUNT 개만 순위 숫자를 단다. */
const RANKED_COUNT = 3;
/** 행 높이 50 + 아래 여백 6 */
const ROW_STEP = 56;

/** 손잡이(☰)를 잡고 끌어 순서를 바꾸는 목록 */
function ReorderList({ order, onReorder }: { order: string[]; onReorder: (from: number, to: number) => void }) {
  const { height } = useWindowDimensions();
  const [drag, setDrag] = useState<{ from: number; dy: number } | null>(null);
  if (order.length === 0) {
    return (
      <HText legacy="caption03" style={{ color: emptyClassTheme.black45, paddingVertical: 12 }}>
        정렬할 건물이 아직 없어요.
      </HText>
    );
  }
  const target = drag ? Math.min(Math.max(drag.from + Math.round(drag.dy / ROW_STEP), 0), order.length - 1) : -1;
  const shiftOf = (i: number): number => {
    if (!drag) return 0;
    if (i === drag.from) return drag.dy;
    if (drag.from < i && i <= target) return -ROW_STEP;
    if (target <= i && i < drag.from) return ROW_STEP;
    return 0;
  };
  return (
    <ScrollView style={{ maxHeight: height * 0.4 }} scrollEnabled={drag === null} nestedScrollEnabled>
      {order.map((name, i) => (
        <Row
          key={name}
          name={name}
          index={i}
          shift={shiftOf(i)}
          lifted={drag?.from === i}
          onDrag={(dy) => setDrag({ from: i, dy })}
          onDrop={(dy) => {
            setDrag(null);
            const to = Math.min(Math.max(i + Math.round(dy / ROW_STEP), 0), order.length - 1);
            // moveItem 은 제거 전 기준 삽입 위치를 받는다
            if (to !== i) onReorder(i, to > i ? to + 1 : to);
          }}
        />
      ))}
    </ScrollView>
  );
}

function Row(props: { name: string; index: number; shift: number; lifted: boolean; onDrag: (dy: number) => void; onDrop: (dy: number) => void }) {
  const { name, index, shift, lifted } = props;
  const latest = useRef(props);
  latest.current = props;
  const pan = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderTerminationRequest: () => false,
      onPanResponderMove: (_, g) => latest.current.onDrag(g.dy),
      onPanResponderRelease: (_, g) => latest.current.onDrop(g.dy),
      onPanResponderTerminate: (_, g) => latest.current.onDrop(g.dy),
    }),
  ).current;
  return (
    <View style={[styles.row, { transform: [{ translateY: shift }], zIndex: lifted ? 1 : 0 }, lifted && styles.lifted]}>
      <View style={{ width: 14 }}>
        {index < RANKED_COUNT ? (
          <HText legacy="caption04" weight="bold" style={{ color: legacyColors.primary, fontVariant: ['tabular-nums'] }}>
            {index + 1}
          </HText>
        ) : null}
      </View>
      <HText legacy="caption01" style={{ flex: 1, marginLeft: 8, color: emptyClassTheme.black87 }}>
        {name}
      </HText>
      <View style={styles.grip} accessibilityLabel={`${name} 순서 바꾸기`} {...pan.panHandlers}>
        <MaterialIcon name="dragHandle" size={22} color={legacyColors.textMuted} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  optionClip: { borderRadius: radius.md, overflow: 'hidden' },
  option: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 10, paddingHorizontal: 4 },
  radio: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  radioDot: { width: 10, height: 10, borderRadius: 5 },
  row: {
    height: 50,
    marginBottom: 6,
    paddingLeft: 12,
    paddingRight: 6,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: legacyColors.subtleBg,
    borderWidth: 1,
    borderColor: legacyColors.cardBorder,
    borderRadius: radius.md,
  },
  lifted: { backgroundColor: colors.white, boxShadow: '0px 2px 8px rgba(0,0,0,0.2)' },
  grip: { padding: 6 },
});
