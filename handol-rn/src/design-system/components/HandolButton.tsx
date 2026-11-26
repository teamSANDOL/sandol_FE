import { ActivityIndicator, StyleSheet, View, type StyleProp, type TextStyle, type ViewStyle } from 'react-native';
import { colors, metrics, radius, spacing } from '../tokens';
import { typography } from '../typography';
import { HText } from './HText';
import { HPressable } from './Pressable';

export type HandolButtonVariant = 'primary' | 'outlined' | 'danger';

type Props = {
  label: string;
  onPress?: () => void;
  isLoading?: boolean;
  variant?: HandolButtonVariant;
  height?: number;
  textStyle?: TextStyle;
  style?: StyleProp<ViewStyle>;
  accessibilityLabel?: string;
  /** 바탕색과 상관없이 1px border 테두리를 두른다 (회원탈퇴 '계속 사용하기' 2:6298) */
  hasBorder?: boolean;
};

const VARIANTS: Record<HandolButtonVariant, { bg: string; fg: string; border?: string }> = {
  primary: { bg: colors.primary, fg: colors.background },
  outlined: { bg: colors.background, fg: colors.text, border: colors.border },
  danger: { bg: colors.red, fg: colors.background },
};

/** 눌림 물결: 채운 버튼은 흰 20%, 흰 바탕(outlined)은 어두운 12% (Material 기본 splash) */
const RIPPLE_ON_FILLED = 'rgba(255,255,255,0.2)';
const RIPPLE_ON_LIGHT = 'rgba(0,0,0,0.12)';

/** 꽉 찬 너비 버튼 (HandolButton) */
export function HandolButton({
  label,
  onPress,
  isLoading = false,
  variant = 'primary',
  height = metrics.buttonHeight,
  textStyle,
  style,
  accessibilityLabel,
  hasBorder = false,
}: Props) {
  const v = VARIANTS[variant];
  const isDisabled = isLoading || !onPress;
  return (
    <View style={[styles.clip, style]}>
      <HPressable
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel ?? label}
        accessibilityState={{ disabled: isDisabled, busy: isLoading }}
        disabled={isDisabled}
        onPress={onPress}
        rippleColor={variant === 'outlined' ? RIPPLE_ON_LIGHT : RIPPLE_ON_FILLED}
        style={[
          styles.base,
          {
            minHeight: height,
            backgroundColor: isDisabled ? colors.muted : v.bg,
            borderColor: hasBorder ? colors.border : v.border ?? 'transparent',
            borderWidth: hasBorder ? 1 : v.border ? StyleSheet.hairlineWidth * 2 : 0,
          },
        ]}
      >
        {isLoading ? (
          <ActivityIndicator color={colors.background} size={24} />
        ) : (
          <HText
            variant="button"
            style={[textStyle ?? typography.button, { color: isDisabled ? colors.background : v.fg, textAlign: 'center' }]}
          >
            {label}
          </HText>
        )}
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden', width: '100%' },
  base: {
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
  },
});
