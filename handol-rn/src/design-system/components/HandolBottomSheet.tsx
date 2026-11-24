import { createContext, useContext, useEffect, useId, useRef, useState, useSyncExternalStore, type ReactNode } from 'react';
import { Animated, BackHandler, Easing, Pressable, StyleSheet, View } from 'react-native';
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
  const progress = useRef(new Animated.Value(0)).current;
  const [isMounted, setIsMounted] = useState(visible);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    if (visible) setIsMounted(true);
    Animated.timing(progress, {
      toValue: visible ? 1 : 0,
      duration: DURATION_MS,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished && !visible) setIsMounted(false);
    });
  }, [visible, progress]);

  useEffect(() => {
    if (!visible) return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      onClose();
      return true;
    });
    return () => sub.remove();
  }, [visible, onClose]);

  if (!isMounted) return null;
  const translateY = progress.interpolate({ inputRange: [0, 1], outputRange: [height || 600, 0] });
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents={visible ? 'auto' : 'none'}>
      <Animated.View style={[StyleSheet.absoluteFill, { backgroundColor: SCRIM, opacity: progress }]}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} accessibilityLabel="닫기" />
      </Animated.View>
      <Animated.View
        onLayout={(e) => setHeight(e.nativeEvent.layout.height)}
        style={[styles.sheet, { backgroundColor, transform: [{ translateY }] }]}
        accessibilityViewIsModal
      >
        {children}
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
});
