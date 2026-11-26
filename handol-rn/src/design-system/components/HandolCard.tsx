import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { colors, radius, shadows } from '../tokens';
import { HPressable } from './Pressable';

type Props = {
  children: ReactNode;
  /** 안쪽 여백. 사진 · 헤더 띠가 모서리까지 닿아야 하면 비운다 */
  padding?: ViewStyle['padding'];
  contentStyle?: StyleProp<ViewStyle>;
  style?: StyleProp<ViewStyle>;
  color?: string;
  /** 기본은 회색. 공지 목록처럼 primary 테두리 카드가 바꾼다 */
  borderColor?: string;
  /** 기본 12. 조직도 카드처럼 16 을 쓰는 카드가 바꾼다 */
  borderRadius?: number;
  /** 그림자 없이 (겹친 카드 등) */
  isFlat?: boolean;
  onPress?: () => void;
  accessibilityLabel?: string;
};

/**
 * 카드 틀: 배경 + 테두리 + 12 모서리 + 옅은 그림자 (HandolCard).
 * 안쪽은 모서리로 잘리고, 그림자는 잘리지 않게 바깥 View 에 둔다.
 * 테두리는 Flutter Material 처럼 내용 위에 겹쳐 그린다(배치 폭을 줄이지 않는다).
 */
export function HandolCard({
  children,
  padding,
  contentStyle,
  style,
  color = colors.background,
  borderColor = colors.border,
  borderRadius = radius.md,
  isFlat = false,
  onPress,
  accessibilityLabel,
}: Props) {
  const inner = [{ backgroundColor: color, borderRadius, padding, overflow: 'hidden' as const }, contentStyle];
  const border = <View pointerEvents="none" style={[StyleSheet.absoluteFill, styles.border, { borderColor, borderRadius }]} />;
  return (
    <View style={[{ borderRadius }, !isFlat && shadows.card, style]}>
      <View style={{ borderRadius, overflow: 'hidden' }}>
        {onPress ? (
          <HPressable accessibilityRole="button" accessibilityLabel={accessibilityLabel} onPress={onPress} style={inner}>
            {children}
          </HPressable>
        ) : (
          <View style={inner}>{children}</View>
        )}
        {border}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  border: { borderWidth: 1 },
});
