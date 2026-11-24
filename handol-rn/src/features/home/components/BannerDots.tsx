import { StyleSheet, View } from 'react-native';
import Animated, { useAnimatedStyle, withTiming } from 'react-native-reanimated';
import { colors, spacing } from '@/design-system';

const DOT = 6;
const ACTIVE_WIDTH = 16;
const DURATION_MS = 200;

function Dot({ isActive }: { isActive: boolean }) {
  const animated = useAnimatedStyle(() => ({ width: withTiming(isActive ? ACTIVE_WIDTH : DOT, { duration: DURATION_MS }) }));
  return <Animated.View style={[styles.dot, { backgroundColor: isActive ? colors.primary : colors.track }, animated]} />;
}

/** 배너 점 표시. 현재 장은 16 길이 (Flutter AnimatedContainer) */
export function BannerDots({ count, page }: { count: number; page: number }) {
  return (
    <View style={styles.row} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
      {Array.from({ length: count }, (_, i) => (
        <Dot key={i} isActive={i === page} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', justifyContent: 'center', gap: spacing.xs },
  dot: { height: DOT, borderRadius: DOT / 2 },
});
