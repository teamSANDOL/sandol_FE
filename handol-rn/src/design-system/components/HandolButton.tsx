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
};

const VARIANTS: Record<HandolButtonVariant, { bg: string; fg: string; border?: string }> = {
  primary: { bg: colors.primary, fg: colors.background },
  outlined: { bg: colors.background, fg: colors.text, border: colors.border },
  danger: { bg: colors.red, fg: colors.background },
};

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
        rippleColor="rgba(255,255,255,0.2)"
        style={[
          styles.base,
          {
            minHeight: height,
            backgroundColor: isDisabled ? colors.muted : v.bg,
            borderColor: v.border ?? 'transparent',
            borderWidth: v.border ? StyleSheet.hairlineWidth * 2 : 0,
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
