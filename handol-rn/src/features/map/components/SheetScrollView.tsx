import { createContext, useContext, useEffect } from 'react';
import { ScrollView, type ScrollViewProps } from 'react-native';
import { GestureDetector } from 'react-native-gesture-handler';
import Animated from 'react-native-reanimated';
import type { SheetScroll } from '../useSnapSheet';

const SheetScrollContext = createContext<SheetScroll | null>(null);

/** 맵 시트가 패널 목록에 스크롤 상태를 건넨다 */
export const SheetScrollProvider = SheetScrollContext.Provider;

/** 패널 목록을 y 로 부드럽게 스크롤 (시트 밖이면 null) */
export function useSheetScrollTo(): ((y: number) => void) | null {
  return useContext(SheetScrollContext)?.scrollToAnimated ?? null;
}

/**
 * 맵 시트 패널의 목록 (Flutter DraggableScrollableSheet 의 ScrollController 를 받은 ListView).
 * 시트 드래그와 동시에 인식되어, 시트가 최대가 아니면 시트가 먼저 움직이고 목록은 제자리에 붙잡힌다.
 */
export function SheetScrollView(props: ScrollViewProps) {
  const s = useContext(SheetScrollContext);
  useEffect(() => s?.reset(), [s]);
  if (!s) return <ScrollView {...props} />;
  return (
    <GestureDetector gesture={s.native}>
      <Animated.ScrollView ref={s.ref} onScroll={s.onScroll} scrollEventThrottle={16} bounces={false} overScrollMode="never" {...props} />
    </GestureDetector>
  );
}
