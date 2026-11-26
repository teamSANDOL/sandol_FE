import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { PanResponder, ScrollView, StyleSheet, View, useWindowDimensions, type ScrollViewInstance } from 'react-native';
import Animated, { Easing, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
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
      <AnimatedSize>
        {settings.mode === 'custom' ? (
          <View style={{ paddingTop: 6 }}>
            <ReorderList order={order} onReorder={(from, to) => buildingSortActions.setCustomOrder(moveItem(order, from, to))} />
          </View>
        ) : null}
      </AnimatedSize>
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
const ROW_H = 50;
const ROW_STEP = 56;
/** 이웃 행이 비켜나고, 놓은 행이 자리를 찾아가는 시간 (SliverReorderableList 250ms easeInOut) */
const SHIFT_MS = 250;
const SHIFT_EASING = Easing.bezier(0.42, 0, 0.58, 1);
/** 끄는 행이 목록 밖으로 나간 만큼(최대 20) 20ms 마다 스크롤 (EdgeDraggingAutoScroller, velocityScalar 50) */
const AUTO_SCROLL_MAX = 20;
const AUTO_SCROLL_TICK_MS = 20;
/** '내 순서' 영역 펼침 · 접힘 (AnimatedSize 200ms easeOutCubic) */
const EXPAND_MS = 200;

type Drag = { from: number; dy: number; /** 끌기 시작할 때 스크롤 위치 */ y0: number; /** 자동 스크롤로 움직인 거리 */ scrolled: number };

/** 손잡이(☰)를 잡고 끌어 순서를 바꾸는 목록. 이웃 행은 비켜나고, 목록 끝으로 끌면 저절로 스크롤된다. */
function ReorderList({ order, onReorder }: { order: string[]; onReorder: (from: number, to: number) => void }) {
  const { height } = useWindowDimensions();
  const scrollRef = useRef<ScrollViewInstance>(null);
  /** 스크롤 위치 · 보이는 높이 */
  const view = useRef({ y: 0, h: 0 });
  const [drag, setDragState] = useState<Drag | null>(null);
  const dragRef = useRef<Drag | null>(null);
  const setDrag = (d: Drag | null) => {
    dragRef.current = d;
    setDragState(d);
  };
  const dragging = drag !== null;
  const contentH = order.length * ROW_STEP;

  useEffect(() => {
    if (!dragging) return;
    const id = setInterval(() => {
      const d = dragRef.current;
      if (!d) return;
      const step = autoScrollStep(d.from * ROW_STEP + d.dy - d.y0, view.current.h);
      const maxY = Math.max(contentH - view.current.h, 0);
      const y = Math.min(Math.max(view.current.y + step, 0), maxY);
      if (Math.abs(y - view.current.y) < 1) return;
      scrollRef.current?.scrollTo({ y, animated: false });
      setDrag({ ...d, scrolled: d.scrolled + y - view.current.y });
      view.current.y = y;
    }, AUTO_SCROLL_TICK_MS);
    return () => clearInterval(id);
  }, [dragging, contentH]);

  if (order.length === 0) {
    return (
      <HText legacy="caption03" style={{ color: emptyClassTheme.black45, paddingVertical: 12 }}>
        정렬할 건물이 아직 없어요.
      </HText>
    );
  }
  const clampIndex = (i: number): number => Math.min(Math.max(i, 0), order.length - 1);
  const targetOf = (d: Drag): number => clampIndex(d.from + Math.round((d.dy + d.scrolled) / ROW_STEP));
  const target = drag ? targetOf(drag) : -1;
  const topOf = (i: number): number => {
    if (!drag) return i * ROW_STEP;
    if (i === drag.from) return i * ROW_STEP + drag.dy + drag.scrolled;
    if (drag.from < i && i <= target) return (i - 1) * ROW_STEP;
    if (target <= i && i < drag.from) return (i + 1) * ROW_STEP;
    return i * ROW_STEP;
  };
  return (
    <ScrollView
      ref={scrollRef}
      style={{ maxHeight: height * 0.4 }}
      scrollEnabled={!dragging}
      nestedScrollEnabled
      scrollEventThrottle={16}
      onScroll={(e) => {
        view.current.y = e.nativeEvent.contentOffset.y;
      }}
      onLayout={(e) => {
        view.current.h = e.nativeEvent.layout.height;
      }}
    >
      <View style={{ height: contentH }}>
        {order.map((name, i) => (
          <Row
            key={name}
            name={name}
            index={i}
            top={topOf(i)}
            lifted={drag?.from === i}
            onDrag={(dy) => setDrag({ from: i, dy, y0: dragRef.current?.y0 ?? view.current.y, scrolled: dragRef.current?.scrolled ?? 0 })}
            onDrop={(dy) => {
              const d = dragRef.current;
              setDrag(null);
              const to = d ? targetOf({ ...d, dy }) : i;
              // moveItem 은 제거 전 기준 삽입 위치를 받는다. 저장소가 바로 바뀌어 같은 렌더에서 새 순서로 그려지므로
              // 놓은 행은 손가락 위치에서 새 자리로 미끄러져 들어간다.
              if (to !== i) onReorder(i, to > i ? to + 1 : to);
            }}
          />
        ))}
      </View>
    </ScrollView>
  );
}

/** 끄는 행(보이는 영역 기준 윗변 y)이 목록 밖으로 나간 만큼, 최대 AUTO_SCROLL_MAX 씩 */
function autoScrollStep(rowTop: number, viewH: number): number {
  if (rowTop < 0) return -Math.min(-rowTop, AUTO_SCROLL_MAX);
  const over = rowTop + ROW_H - viewH;
  return over > 0 ? Math.min(over, AUTO_SCROLL_MAX) : 0;
}

function Row(props: { name: string; index: number; top: number; lifted: boolean; onDrag: (dy: number) => void; onDrop: (dy: number) => void }) {
  const { name, index, top, lifted } = props;
  const latest = useRef(props);
  latest.current = props;
  const y = useSharedValue(top);
  const animStyle = useAnimatedStyle(() => ({ top: y.value }));
  useLayoutEffect(() => {
    // 끄는 행은 손가락을 그대로 따르고, 나머지(놓은 행 포함)는 새 자리로 미끄러진다.
    y.value = lifted ? top : withTiming(top, { duration: SHIFT_MS, easing: SHIFT_EASING });
  }, [top, lifted, y]);
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
    <Animated.View style={[styles.row, animStyle, { zIndex: lifted ? 1 : 0 }, lifted && styles.lifted]}>
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
    </Animated.View>
  );
}

/** 내용 높이가 바뀌면 그 높이로 부드럽게 늘고 준다 (Flutter AnimatedSize, 위쪽 기준) */
function AnimatedSize({ children }: { children: ReactNode }) {
  const h = useSharedValue(-1);
  const style = useAnimatedStyle(() => (h.value < 0 ? {} : { height: h.value }));
  return (
    <Animated.View style={[{ overflow: 'hidden' }, style]}>
      <View
        onLayout={(e) => {
          const next = e.nativeEvent.layout.height;
          // 처음 잰 높이는 그대로 (AnimatedSize 도 첫 빌드는 움직이지 않는다)
          h.value = h.value < 0 ? next : withTiming(next, { duration: EXPAND_MS, easing: Easing.out(Easing.cubic) });
        }}
      >
        {children}
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  optionClip: { borderRadius: radius.md, overflow: 'hidden' },
  option: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 10, paddingHorizontal: 4 },
  radio: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  radioDot: { width: 10, height: 10, borderRadius: 5 },
  row: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: ROW_H,
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
