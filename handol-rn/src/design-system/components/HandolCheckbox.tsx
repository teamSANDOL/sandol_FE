import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, { Easing, interpolateColor, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { MaterialIcon } from './MaterialIcon';
import { colors, radius, spacing } from '../tokens';
import { HText } from './HText';
import { HPressable } from './Pressable';

type Props = {
  label: string;
  isChecked: boolean;
  onChange: (next: boolean) => void;
  /** 24px 원 + 캡션 라벨 (회원탈퇴 동의, Figma 2:6346: 흰 바탕 원, #D5DAE5 테두리) */
  isDense?: boolean;
};

function Check({ size }: { size: number }) {
  return <MaterialIcon name="check" size={size} color={colors.background} />;
}

/** 체크 색 전환 (Flutter AnimatedContainer 120ms, 선형) */
const CHECK_TIMING = { duration: 120, easing: Easing.linear };

/** 체크박스 + 라벨 (HandolCheckbox) */
export function HandolCheckbox({ label, isChecked, onChange, isDense = false }: Props) {
  const box = isDense ? 24 : 32;
  const offColor = isDense ? colors.background : colors.field;
  const on = useSharedValue(isChecked ? 1 : 0);
  useEffect(() => {
    on.value = withTiming(isChecked ? 1 : 0, CHECK_TIMING);
  }, [isChecked, on]);
  const colorStyle = useAnimatedStyle(() => ({ backgroundColor: interpolateColor(on.value, [0, 1], [offColor, colors.primary]) }));
  return (
    <HPressable
      accessibilityRole="checkbox"
      accessibilityLabel={label}
      accessibilityState={{ checked: isChecked }}
      onPress={() => onChange(!isChecked)}
      style={styles.row}
    >
      <Animated.View style={[styles.box, { width: box, height: box, borderRadius: isDense ? box / 2 : radius.md }, colorStyle]}>
        {isChecked && <Check size={isDense ? 16 : 22} />}
      </Animated.View>
      <View style={{ width: isDense ? spacing.xs : spacing.sm }} />
      <HText variant={isDense ? 'caption' : 'body'} tone="muted" style={{ flex: 1 }}>
        {label}
      </HText>
    </HPressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6, borderRadius: radius.md },
  box: { borderWidth: 1, borderColor: colors.fieldBorder, alignItems: 'center', justifyContent: 'center' },
});
