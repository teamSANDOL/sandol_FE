import { StyleSheet, View } from 'react-native';
import { MaterialIcon } from './MaterialIcon';
import { colors, radius, spacing } from '../tokens';
import { HText } from './HText';
import { HPressable } from './Pressable';

type Props = {
  label: string;
  isChecked: boolean;
  onChange: (next: boolean) => void;
  /** 24px 회색 상자 + 캡션 라벨 (회원탈퇴 동의, Figma 2196:1207) */
  isDense?: boolean;
};

function Check({ size }: { size: number }) {
  return <MaterialIcon name="check" size={size} color={colors.background} />;
}

/** 체크박스 + 라벨 (HandolCheckbox) */
export function HandolCheckbox({ label, isChecked, onChange, isDense = false }: Props) {
  const box = isDense ? 24 : 32;
  return (
    <HPressable
      accessibilityRole="checkbox"
      accessibilityLabel={label}
      accessibilityState={{ checked: isChecked }}
      onPress={() => onChange(!isChecked)}
      style={styles.row}
    >
      <View
        style={[
          styles.box,
          {
            width: box,
            height: box,
            borderRadius: isDense ? 6 : radius.md,
            backgroundColor: isChecked ? colors.primary : isDense ? colors.inactive : colors.field,
          },
        ]}
      >
        {isChecked && <Check size={isDense ? 16 : 22} />}
      </View>
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
