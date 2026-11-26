import { useEffect, useSyncExternalStore } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, { FadeIn, FadeOut } from 'react-native-reanimated';
import { useSegments } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { metrics } from '../tokens';
import { HText } from './HText';
import { getToast, hideToast, subscribeToast } from './toast';

/** Material 스낵바 등장·퇴장 (_snackBarTransitionDuration) */
const FADE_MS = 250;
/** Material 3 floating 스낵바 바깥 여백 (좌우 15, 아래 10) */
const MARGIN_H = 15;
const MARGIN_BOTTOM = 10;
const SNACKBAR_BG = '#313033';
const SNACKBAR_FG = '#F4EFF4';

/**
 * showToast 로 띄운 안내를 그리는 자리. 루트 레이아웃에 하나 둔다.
 * 탭 셸 안에서는 Flutter 처럼 하단 네비 위에 뜬다.
 */
export function ToastHost() {
  const toast = useSyncExternalStore(subscribeToast, getToast);
  const insets = useSafeAreaInsets();
  const isInTabs = useSegments()[0] === '(tabs)';

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => hideToast(toast.id), toast.durationMs);
    return () => clearTimeout(timer);
  }, [toast]);

  const bottom = insets.bottom + MARGIN_BOTTOM + (isInTabs ? metrics.bottomNavHeight : 0);
  return (
    <View style={[StyleSheet.absoluteFill, styles.layer, { paddingBottom: bottom }]} pointerEvents="none">
      {toast && (
        <Animated.View key={toast.id} entering={FadeIn.duration(FADE_MS)} exiting={FadeOut.duration(FADE_MS)} style={styles.bar} accessibilityLiveRegion="polite">
          <HText variant="caption" style={styles.text}>
            {toast.message}
          </HText>
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  layer: { justifyContent: 'flex-end', paddingHorizontal: MARGIN_H },
  bar: { backgroundColor: SNACKBAR_BG, borderRadius: 4, paddingHorizontal: 16, paddingVertical: 14, boxShadow: '0 3px 6px rgba(0,0,0,0.3)' },
  text: { color: SNACKBAR_FG },
});
