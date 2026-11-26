import { useCallback, useMemo, useState } from 'react';
import { Gesture } from 'react-native-gesture-handler';
import Animated, {
  Easing,
  cancelAnimation,
  runOnJS,
  scrollTo,
  useAnimatedReaction,
  useAnimatedRef,
  useAnimatedScrollHandler,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { COVER_FRAC, minFracOf, pickSnapTarget } from './panels';

const SHEET_ANIM_MS = 280;
const SHEET_EASING = Easing.out(Easing.cubic);
/** 시트가 이만큼(비율) 오르기 전에 지도 위 버튼이 먼저 사라진다 */
const BUTTON_HIDE_FRAC = COVER_FRAC - 0.1;
/** 세로로 이만큼 움직여야 시트 드래그로 본다 (가로 스크롤 · 탭과 구분) */
const DRAG_SLOP = 8;
/** 패널 목록을 건물 카드로 옮기는 스크롤 (empty_class_panel.dart ensureVisible 300ms easeOut) */
const SCROLL_ANIM_MS = 300;
const SCROLL_EASING = Easing.bezier(0, 0, 0.58, 1);

export type SheetFlags = { covered: boolean; buttonsHidden: boolean };

/**
 * 맵 시트 높이 제어 (Flutter DraggableScrollableSheet). 높이는 px 공유값 하나이고, 시트 어디서든 끌면
 * 목록보다 시트가 먼저 움직인다: 위로 밀면 최대 높이까지 시트가 커진 뒤 목록이 스크롤되고, 목록이 맨 위일 때
 * 아래로 끌면 시트가 내려간다. 놓으면 접힘 · 중간 · 최대 세 정지점에 스냅한다.
 * 패널 목록은 SheetScrollView 로 그려 이 훅의 scroll 을 받아야 한다.
 */
export function useSnapSheet({ bodyH, initialFrac, initialMaxFrac }: { bodyH: number; initialFrac: number; initialMaxFrac: number }) {
  const minFrac = minFracOf(bodyH);
  const height = useSharedValue(initialFrac * bodyH);
  /** 지금 패널이 올라갈 수 있는 최대 높이(비율). 패널이 바뀔 때 호출하는 쪽이 갱신한다 */
  const maxFrac = useSharedValue(initialMaxFrac);
  /** 이번 드래그에서 시트가 움직였는가 (안 움직였으면 놓아도 스냅하지 않는다) */
  const moved = useSharedValue(false);
  const [flags, setFlags] = useState<SheetFlags>({ covered: false, buttonsHidden: false });

  useAnimatedReaction(
    () => {
      const frac = height.value / bodyH;
      return { covered: frac > COVER_FRAC, buttonsHidden: frac > BUTTON_HIDE_FRAC };
    },
    (cur, prev) => {
      if (prev && cur.covered === prev.covered && cur.buttonsHidden === prev.buttonsHidden) return;
      runOnJS(setFlags)(cur);
    },
    [bodyH],
  );

  const animateTo = useCallback(
    (frac: number) =>
      new Promise<void>((resolve) => {
        height.value = withTiming(frac * bodyH, { duration: SHEET_ANIM_MS, easing: SHEET_EASING }, () => runOnJS(resolve)());
      }),
    [height, bodyH],
  );

  const scroll = useSheetScroll();
  const { ref: scrollRef, y: scrollY, locked, lockY, native } = scroll;

  const gesture = useMemo(
    () =>
      Gesture.Pan()
      .activeOffsetY([-DRAG_SLOP, DRAG_SLOP])
      .simultaneousWithExternalGesture(native)
      .onStart(() => {
        cancelAnimation(height);
        cancelAnimation(scroll.anim);
        moved.value = false;
        lockY.value = scrollY.value;
      })
      .onChange((e) => {
        const minH = minFrac * bodyH;
        const maxH = maxFrac.value * bodyH;
        // 위로: 최대가 될 때까지 시트 먼저. 아래로: 목록이 맨 위일 때만 시트가 내려간다.
        const sheetFirst = e.changeY < 0 ? height.value < maxH : scrollY.value <= 0 && height.value > minH;
        if (!sheetFirst) {
          locked.value = false;
          lockY.value = scrollY.value;
          return;
        }
        locked.value = true;
        moved.value = true;
        height.value = Math.min(Math.max(height.value - e.changeY, minH), maxH);
        scrollTo(scrollRef, 0, lockY.value, false);
      })
      .onEnd((e) => {
        if (!moved.value) return;
        // velocityY: px/s (아래가 양수) → 비율/초, 위로 올리는 방향이 양수
        const target = pickSnapTarget(height.value / bodyH, -e.velocityY / bodyH, minFrac, maxFrac.value);
        height.value = withTiming(target * bodyH, { duration: SHEET_ANIM_MS, easing: SHEET_EASING }, () => {
          locked.value = false;
        });
      })
      .onFinalize(() => {
        if (!moved.value) locked.value = false;
      }),
    [bodyH, minFrac, height, maxFrac, moved, native, locked, lockY, scrollY, scrollRef, scroll.anim],
  );

  return { height, minFrac, maxFrac, animateTo, gesture, scroll, flags, currentFrac: () => height.value / bodyH };
}

/** 시트 안 목록 하나(지금 보이는 패널)의 스크롤 상태 */
function useSheetScroll() {
  const ref = useAnimatedRef<Animated.ScrollView>();
  const y = useSharedValue(0);
  /** 시트가 움직이는 동안 목록을 lockY 에 붙잡아 둔다 (놓은 뒤 관성 스크롤 포함) */
  const locked = useSharedValue(false);
  const lockY = useSharedValue(0);
  /** 코드로 움직이는 스크롤 위치 (scrollToAnimated) */
  const anim = useSharedValue(-1);
  const native = useMemo(() => Gesture.Native(), []);

  const onScroll = useAnimatedScrollHandler({
    onScroll: (e) => {
      if (locked.value) {
        scrollTo(ref, 0, lockY.value, false);
        return;
      }
      y.value = e.contentOffset.y;
    },
  });

  useAnimatedReaction(
    () => anim.value,
    (v, prev) => {
      if (v >= 0 && v !== prev) scrollTo(ref, 0, v, false);
    },
  );

  /** 패널이 바뀌어 새 목록이 붙을 때 */
  const reset = useCallback(() => {
    y.value = 0;
    lockY.value = 0;
  }, [y, lockY]);

  /** y 로 300ms easeOut 스크롤 (Flutter Scrollable.ensureVisible) */
  const scrollToAnimated = useCallback(
    (to: number) => {
      anim.value = y.value;
      anim.value = withTiming(Math.max(to, 0), { duration: SCROLL_ANIM_MS, easing: SCROLL_EASING }, () => {
        anim.value = -1;
      });
    },
    [anim, y],
  );

  return { ref, y, locked, lockY, anim, native, onScroll, reset, scrollToAnimated };
}

export type SheetScroll = ReturnType<typeof useSheetScroll>;
