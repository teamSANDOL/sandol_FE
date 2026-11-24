import { useLayoutEffect, useMemo, useRef, useState } from 'react';
import { PanResponder, StyleSheet, View } from 'react-native';
import { colors } from '@/design-system';
import { emptyClassTheme } from '../theme';

export const THUMB_RADIUS = 12.2;
const TRACK_HEIGHT = 12;

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

/** 이산 두 손잡이 슬라이더 (Flutter RangeSlider + divisions). 두 손잡이가 겹치는 이동은 받지 않는다. */
export function RangeSlider({ count, value, onChange, onChangeEnd }: Props) {
  const [width, setWidth] = useState(0);
  const live = useRef({ count, value, width, onChange, onChangeEnd });
  const drag = useRef<{ thumb: 'start' | 'end'; x0: number; cur: RangeValue } | null>(null);
  useLayoutEffect(() => {
    live.current = { count, value, width, onChange, onChangeEnd };
  });

  const pan = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onPanResponderTerminationRequest: () => false,
        onPanResponderGrant: (e) => {
          const { count: n, value: v, width: w } = live.current;
          const x0 = e.nativeEvent.locationX;
          const i = indexAt(x0, w, n);
          const thumb = Math.abs(i - v.start) <= Math.abs(i - v.end) ? 'start' : 'end';
          drag.current = { thumb, x0, cur: v };
        },
        onPanResponderMove: (_, g) => {
          const d = drag.current;
          if (!d) return;
          const { count: n, width: w } = live.current;
          const i = indexAt(d.x0 + g.dx, w, n);
          const next = d.thumb === 'start' ? { start: i, end: d.cur.end } : { start: d.cur.start, end: i };
          if (next.end - next.start < 1) return;
          if (next.start === d.cur.start && next.end === d.cur.end) return;
          d.cur = next;
          live.current.onChange(next);
        },
        onPanResponderRelease: () => {
          const d = drag.current;
          drag.current = null;
          if (d) live.current.onChangeEnd(d.cur);
        },
        onPanResponderTerminate: () => {
          const d = drag.current;
          drag.current = null;
          if (d) live.current.onChangeEnd(d.cur);
        },
      }),
    [],
  );

  const span = Math.max(width - THUMB_RADIUS * 2, 0);
  const xOf = (i: number): number => THUMB_RADIUS + (count > 1 ? (i / (count - 1)) * span : 0);

  return (
    <View
      style={styles.root}
      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
      accessibilityRole="adjustable"
      accessibilityLabel="조회 시간 구간"
      {...pan.panHandlers}
    >
      <View pointerEvents="none" style={styles.fill}>
        <View style={[styles.track, { left: THUMB_RADIUS, right: THUMB_RADIUS }]} />
        <View style={[styles.active, { left: xOf(value.start), width: xOf(value.end) - xOf(value.start) }]} />
        <View style={[styles.thumb, { left: xOf(value.start) - THUMB_RADIUS }]} />
        <View style={[styles.thumb, { left: xOf(value.end) - THUMB_RADIUS }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { height: THUMB_RADIUS * 2 },
  fill: { flex: 1, justifyContent: 'center' },
  track: { position: 'absolute', height: TRACK_HEIGHT, borderRadius: TRACK_HEIGHT / 2, backgroundColor: colors.track },
  active: { position: 'absolute', height: TRACK_HEIGHT, borderRadius: TRACK_HEIGHT / 2, backgroundColor: colors.primary },
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
