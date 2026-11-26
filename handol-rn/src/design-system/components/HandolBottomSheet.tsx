import { createContext, useContext, useEffect, useId, useState, useSyncExternalStore, type ReactNode } from 'react';
import { BackHandler, Pressable, StyleSheet, View } from 'react-native';
import { GestureDetector, usePanGesture } from 'react-native-gesture-handler';
import Animated, { cancelAnimation, Easing, runOnJS, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { colors, radius } from '../tokens';

type Props = {
  visible: boolean;
  onClose: () => void;
  children: ReactNode;
  /** 시트 바탕색. Flutter 시트마다 background(#FDFDFD) · white 를 따로 쓴다 */
  backgroundColor?: string;
};

const DURATION_MS = 250;
const SCRIM = 'rgba(0,0,0,0.54)'; // Material BottomSheet 기본 barrier (black54)
const SHEET_TIMING = { duration: DURATION_MS, easing: Easing.out(Easing.cubic) };
/** 아직 높이를 못 쟀을 때 화면 밖으로 내려 둘 거리 */
const FALLBACK_HEIGHT = 600;
/** 아래로 끌어 닫기 (Flutter BottomSheet: 속도 700 넘게 튕기거나 절반 아래로 내리면 닫힘) */
const CLOSE_FLING_VELOCITY = 700;
const CLOSE_PROGRESS = 0.5;
/** 이만큼 아래로 움직여야 시트 끌기가 시작된다. 위로 먼저 움직이면 양보한다 */
const DRAG_SLOP = 10;
/**
 * 끌어 닫기는 시트 윗부분(손잡이 줄)에서만 받는다. 시트 전체에 걸면 안쪽 목록을 아래로 스크롤하거나
 * 건물 순서를 끌어 옮길 때 시트가 대신 닫힌다(Flutter 는 안쪽 스크롤이 먼저 가져간다).
 */
const DRAG_ZONE_H = 32;

// ── 시트 호스트(포털) ───────────────────────────────────────────────
// Flutter showModalBottomSheet 는 탭 셸 Scaffold 의 body 위에 뜬다: 탭 씬 전체를 덮고, 탭 바는 덮지 않는다.
// RN Modal 은 창 전체(탭 바 포함)를 덮으므로, 탭 씬 위에 놓인 호스트로 시트를 옮겨 그린다.
type Entry = { id: string; node: ReactNode };
let entries: Entry[] = [];
const listeners = new Set<() => void>();
const emit = () => listeners.forEach((l) => l());
function setEntry(id: string, node: ReactNode | null) {
  entries = node === null ? entries.filter((e) => e.id !== id) : [...entries.filter((e) => e.id !== id), { id, node }];
  emit();
}

const HostContext = createContext(false);

/** 탭 씬 위에 시트를 그리는 자리. 탭 레이아웃(또는 셸 밖 화면의 루트)에 하나 둔다 */
export function BottomSheetHost({ children }: { children: ReactNode }) {
  const list = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => entries,
  );
  return (
    <HostContext.Provider value>
      <View style={{ flex: 1 }}>
        {children}
        {list.map((e) => (
          <View key={e.id} style={StyleSheet.absoluteFill} pointerEvents="box-none">
            {e.node}
          </View>
        ))}
      </View>
    </HostContext.Provider>
  );
}

/**
 * 모달 바텀시트 (Flutter showModalBottomSheet 대응). 위쪽 12 모서리, 배경 딤, 아래에서 밀려 올라온다.
 * BottomSheetHost 안이면 호스트 자리(탭 씬 위)에, 아니면 이 자리(부모 화면 위)에 그린다.
 */
export function HandolBottomSheet({ visible, onClose, children, backgroundColor }: Props) {
  const hasHost = useContext(HostContext);
  const id = useId();
  // 호스트는 이 컴포넌트의 렌더 결과를 받아 그린다. 렌더마다 노드를 넘기면 호스트가 다시 그려 무한 반복이 되므로
  // 시트 입력(visible · 내용 · 콜백 · 색)이 바뀔 때만 넘긴다.
  useEffect(() => {
    if (!hasHost) return;
    setEntry(id, <SheetLayer visible={visible} onClose={onClose} backgroundColor={backgroundColor}>{children}</SheetLayer>);
  }, [hasHost, id, visible, onClose, children, backgroundColor]);
  useEffect(() => () => setEntry(id, null), [id]);
  if (hasHost) return null;
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="box-none">
      <SheetLayer visible={visible} onClose={onClose} backgroundColor={backgroundColor}>
        {children}
      </SheetLayer>
    </View>
  );
}

function SheetLayer({ visible, onClose, children, backgroundColor = colors.background }: Props) {
  // progress: 0 = 닫힘, 1 = 다 올라옴. 끄는 동안에도 이 값을 손가락에 맞춰 움직인다(Flutter 와 같다)
  const progress = useSharedValue(0);
  const height = useSharedValue(0);
  const dragStart = useSharedValue(1);
  const [isMounted, setIsMounted] = useState(visible);

  useEffect(() => {
    if (visible) setIsMounted(true);
    progress.value = withTiming(visible ? 1 : 0, SHEET_TIMING, (finished) => {
      if (finished && !visible) runOnJS(setIsMounted)(false);
    });
  }, [visible, progress]);

  const drag = usePanGesture({
    activeOffsetY: DRAG_SLOP,
    failOffsetY: -DRAG_SLOP,
    onActivate: () => {
      'worklet';
      cancelAnimation(progress);
      dragStart.value = progress.value;
    },
    onUpdate: (e) => {
      'worklet';
      const next = dragStart.value - e.translationY / (height.value || FALLBACK_HEIGHT);
      progress.value = Math.min(1, Math.max(0, next));
    },
    onDeactivate: (e) => {
      'worklet';
      if (e.velocityY > CLOSE_FLING_VELOCITY || progress.value < CLOSE_PROGRESS) runOnJS(onClose)();
      else progress.value = withTiming(1, SHEET_TIMING);
    },
  });

  const scrimStyle = useAnimatedStyle(() => ({ opacity: progress.value }));
  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: (1 - progress.value) * (height.value || FALLBACK_HEIGHT) }],
  }));

  useEffect(() => {
    if (!visible) return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      onClose();
      return true;
    });
    return () => sub.remove();
  }, [visible, onClose]);

  if (!isMounted) return null;
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents={visible ? 'auto' : 'none'}>
      <Animated.View style={[StyleSheet.absoluteFill, { backgroundColor: SCRIM }, scrimStyle]}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} accessibilityLabel="닫기" />
      </Animated.View>
      <Animated.View
        onLayout={(e) => (height.value = e.nativeEvent.layout.height)}
        style={[styles.sheet, { backgroundColor }, sheetStyle]}
        accessibilityViewIsModal
      >
        {children}
        <GestureDetector gesture={drag}>
          <View style={styles.dragZone} />
        </GestureDetector>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  sheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    maxHeight: '90%',
    borderTopLeftRadius: radius.md,
    borderTopRightRadius: radius.md,
    overflow: 'hidden',
  },
  dragZone: { position: 'absolute', top: 0, left: 0, right: 0, height: DRAG_ZONE_H },
});
