import { useLayoutEffect, useMemo, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import * as Haptics from 'expo-haptics';
import { colors } from '@/design-system';
import { emptyClassTheme } from '../theme';

export const THUMB_RADIUS = 12.2;
const TRACK_HEIGHT = 12;
/** 잡은 손잡이 뒤 원 반지름 (RoundSliderOverlayShape overlayRadius 20) */
const OVERLAY_RADIUS = 20;
/** 가로로 이만큼 움직여야 슬라이더가 잡는다. 세로로 먼저 움직이면 부모 스크롤에 양보한다 */
const DRAG_SLOP = 10;

export interface RangeValue {
  start: number;
  end: number;
}

interface Props {
  /** 디텐트(칸) 수. 값은 0 .. count-1 의 정수 */
  count: number;
  value: RangeValue;
  /** 드래그 중 값이 바뀔 때 */
  onChange: (v: RangeValue) => void;
  /** 손을 뗄 때 */
  onChangeEnd: (v: RangeValue) => void;
}

/** x 좌표 → 가장 가까운 칸 */
export function indexAt(x: number, width: number, count: number): number {
  const span = width - THUMB_RADIUS * 2;
  if (span <= 0 || count < 2) return 0;
  const i = Math.round(((x - THUMB_RADIUS) / span) * (count - 1));
  return Math.min(Math.max(i, 0), count - 1);
}

/**
 * 이산 두 손잡이 슬라이더 (Flutter RangeSlider + divisions). 트랙을 누르면 가까운 손잡이가 그 칸으로 옮겨 확정되고,
 * 가로로 끌면 손잡이를 움직인다. 칸이 바뀔 때마다 선택 햅틱. 두 손잡이가 겹치는 이동은 받지 않는다.
 */
export function RangeSlider({ count, value, onChange, onChangeEnd }: Props) {
  const [width, setWidth] = useState(0);
  /** 잡고 있는 손잡이 (뒤에 원을 그린다) */
  const [held, setHeld] = useState<'start' | 'end' | null>(null);
  const live = useRef({ count, value, width, onChange, onChangeEnd });
  const drag = useRef<{ thumb: 'start' | 'end'; cur: RangeValue } | null>(null);
  useLayoutEffect(() => {
    live.current = { count, value, width, onChange, onChangeEnd };
  });

  const gesture = useMemo(() => {
    const begin = (x: number) => {
      const { count: n, value: v, width: w } = live.current;
      const i = indexAt(x, w, n);
      const thumb = Math.abs(i - v.start) <= Math.abs(i - v.end) ? 'start' : 'end';
      drag.current = { thumb, cur: v };
      setHeld(thumb);
    };
    const moveTo = (x: number) => {
      const d = drag.current;
      if (!d) return;
      const { count: n, width: w } = live.current;
      const i = indexAt(x, w, n);
      const next = d.thumb === 'start' ? { start: i, end: d.cur.end } : { start: d.cur.start, end: i };
      if (next.end - next.start < 1) return;
      if (next.start === d.cur.start && next.end === d.cur.end) return;
      d.cur = next;
      void Haptics.selectionAsync();
      live.current.onChange(next);
    };
    const end = () => {
      const d = drag.current;
      drag.current = null;
      setHeld(null);
      if (d) live.current.onChangeEnd(d.cur);
    };
    const pan = Gesture.Pan()
      .runOnJS(true)
      .activeOffsetX([-DRAG_SLOP, DRAG_SLOP])
      .failOffsetY([-DRAG_SLOP, DRAG_SLOP])
      .onStart((e) => {
        begin(e.x - e.translationX);
        moveTo(e.x);
      })
      .onUpdate((e) => moveTo(e.x))
      .onFinalize(end);
    const tap = Gesture.Tap()
      .runOnJS(true)
      .onEnd((e, success) => {
        if (!success) return;
        begin(e.x);
        moveTo(e.x);
        end();
      });
    return Gesture.Race(pan, tap);
  }, []);

  const span = Math.max(width - THUMB_RADIUS * 2, 0);
  const xOf = (i: number): number => THUMB_RADIUS + (count > 1 ? (i / (count - 1)) * span : 0);
  const heldX = held ? xOf(held === 'start' ? value.start : value.end) : 0;

  return (
    <GestureDetector gesture={gesture}>
      <View
        style={styles.root}
        onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
        accessibilityRole="adjustable"
        accessibilityLabel="조회 시간 구간"
      >
        <View pointerEvents="none" style={styles.fill}>
          <View style={[styles.track, { left: THUMB_RADIUS, right: THUMB_RADIUS }]} />
          <View style={[styles.active, { left: xOf(value.start), width: xOf(value.end) - xOf(value.start) }]} />
          {held ? <View style={[styles.overlay, { left: heldX - OVERLAY_RADIUS }]} /> : null}
          <View style={[styles.thumb, { left: xOf(value.start) - THUMB_RADIUS }]} />
          <View style={[styles.thumb, { left: xOf(value.end) - THUMB_RADIUS }]} />
        </View>
      </View>
    </GestureDetector>
  );
}

const styles = StyleSheet.create({
  root: { height: THUMB_RADIUS * 2 },
  fill: { flex: 1, justifyContent: 'center' },
  track: { position: 'absolute', height: TRACK_HEIGHT, borderRadius: TRACK_HEIGHT / 2, backgroundColor: colors.track },
  active: { position: 'absolute', height: TRACK_HEIGHT, borderRadius: TRACK_HEIGHT / 2, backgroundColor: colors.primary },
  overlay: { position: 'absolute', width: OVERLAY_RADIUS * 2, height: OVERLAY_RADIUS * 2, borderRadius: OVERLAY_RADIUS, backgroundColor: emptyClassTheme.thumbOverlay },
  thumb: {
    position: 'absolute',
    width: THUMB_RADIUS * 2,
    height: THUMB_RADIUS * 2,
    borderRadius: THUMB_RADIUS,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.background,
    boxShadow: emptyClassTheme.thumbShadow,
  },
});
