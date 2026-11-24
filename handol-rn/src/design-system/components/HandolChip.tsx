import { StyleSheet, View } from 'react-native';
import { colors, radius, spacing } from '../tokens';
import { HText } from './HText';
import { HPressable } from './Pressable';

/** outline: 흰 바탕 · 회색 테두리 (홈 2153:231) / solid: 회색 바탕 흰 글씨 (학식 2158:731) */
export type HandolChipStyle = 'outline' | 'solid';

type Props = {
  label: string;
  isSelected: boolean;
  onPress: () => void;
  chipStyle?: HandolChipStyle;
};

export const CHIP_HEIGHT = 39;
export const CHIP_MIN_WIDTH = 98;

/** 선택 칩. 선택되면 primary 바탕에 굵은 흰 글씨 (HandolChip) */
export function HandolChip({ label, isSelected, onPress, chipStyle = 'outline' }: Props) {
  const bg = isSelected ? colors.primary : chipStyle === 'outline' ? colors.background : colors.inactive;
  const hasBorder = !isSelected && chipStyle === 'outline';
  const textColor = isSelected || chipStyle === 'solid' ? colors.background : colors.textSecondary;
  return (
    <View style={styles.clip}>
      <HPressable
        accessibilityRole="button"
        accessibilityState={{ selected: isSelected }}
        onPress={onPress}
        style={[styles.chip, { backgroundColor: bg, borderColor: hasBorder ? colors.border : 'transparent' }]}
      >
        <HText variant="caption" weight={isSelected ? 'bold' : undefined} style={{ color: textColor }}>
          {label}
        </HText>
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  chip: {
    height: CHIP_HEIGHT,
    minWidth: CHIP_MIN_WIDTH,
    paddingHorizontal: spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.md,
    borderWidth: 1,
  },
});
