import { useCallback, useEffect, useMemo, useRef, useState, type MutableRefObject } from 'react';
import { Animated, Easing, PanResponder } from 'react-native';
import { COVER_FRAC, minFracOf, pickSnapTarget } from './panels';

const SHEET_ANIM_MS = 280;
/** 시트가 이만큼(비율) 오르기 전에 지도 위 버튼이 먼저 사라진다 */
const BUTTON_HIDE_FRAC = COVER_FRAC - 0.1;

/**
 * 맵 시트 높이 제어 (Flutter DraggableScrollableSheet + 손잡이). 높이는 px Animated.Value 하나이고,
 * 손잡이 드래그로 움직여 접힘 · 중간 · 최대 세 정지점에 스냅한다.
 */
export function useSnapSheet({
  bodyH,
  initialFrac,
  maxFracRef,
}: {
  bodyH: number;
  initialFrac: number;
  /** 지금 패널이 올라갈 수 있는 최대 높이(비율). 패널이 바뀔 때 호출하는 쪽이 갱신한다 */
  maxFracRef: MutableRefObject<number>;
}) {
  const minFrac = minFracOf(bodyH);
  const height = useRef(new Animated.Value(initialFrac * bodyH)).current;
  const current = useRef(initialFrac * bodyH);
  const initialH = useRef(initialFrac * bodyH);
  const maxRef = maxFracRef;
  const [flags, setFlags] = useState({ covered: false, buttonsHidden: false, moved: false });

  useEffect(() => {
    const id = height.addListener(({ value }) => {
      current.current = value;
      const frac = value / bodyH;
      const covered = frac > COVER_FRAC;
      const buttonsHidden = frac > BUTTON_HIDE_FRAC;
      // 높이가 한 번이라도 바뀌었는가 (map_screen.dart 의 버튼 위치 계산이 이전까지 접힘 높이를 쓴다)
      const moved = Math.abs(value - initialH.current) > 0.5;
      setFlags((p) =>
        p.covered === covered && p.buttonsHidden === buttonsHidden && (p.moved || !moved)
          ? p
          : { covered, buttonsHidden, moved: p.moved || moved },
      );
    });
    return () => height.removeListener(id);
  }, [height, bodyH]);

  const animateTo = useCallback(
    (frac: number) =>
      new Promise<void>((resolve) => {
        Animated.timing(height, {
          toValue: frac * bodyH,
          duration: SHEET_ANIM_MS,
          easing: Easing.out(Easing.cubic),
          useNativeDriver: false,
        }).start(() => resolve());
      }),
    [height, bodyH],
  );

  const gripHandlers = useMemo(() => {
    let startH = 0;
    const release = (vy: number) => {
      // vy: px/ms (아래가 양수) → 비율/초, 위로 올리는 방향이 양수
      void animateTo(pickSnapTarget(current.current / bodyH, (-vy * 1000) / bodyH, minFrac, maxRef.current));
    };
    return PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderTerminationRequest: () => false,
      onPanResponderGrant: () => {
        height.stopAnimation();
        startH = current.current;
      },
      onPanResponderMove: (_, g) => {
        height.setValue(Math.min(Math.max(startH - g.dy, minFrac * bodyH), maxRef.current * bodyH));
      },
      onPanResponderRelease: (_, g) => release(g.vy),
      onPanResponderTerminate: (_, g) => release(g.vy),
    }).panHandlers;
  }, [animateTo, bodyH, height, minFrac, maxRef]);

  return { height, minFrac, animateTo, gripHandlers, flags, currentFrac: () => current.current / bodyH };
}