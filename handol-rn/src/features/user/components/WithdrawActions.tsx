import { View } from 'react-native';
import { HandolButton, spacing, typography } from '@/design-system';

/** `계속 사용하기` · 빨간 확인 버튼 한 쌍 (2196:1174 · 2196:1177). 회원탈퇴 두 화면이 같이 쓴다. */
export function WithdrawActions({
  confirmLabel,
  onContinue,
  onConfirm,
}: {
  confirmLabel: string;
  onContinue: () => void;
  /** undefined 면 비활성(회색) */
  onConfirm?: () => void;
}) {
  return (
    <View style={{ flexDirection: 'row', gap: spacing.lg }}>
      <View style={{ flex: 1 }}>
        <HandolButton label="계속 사용하기" variant="primary" height={69} textStyle={typography.title} onPress={onContinue} />
      </View>
      <View style={{ flex: 1 }}>
        <HandolButton label={confirmLabel} variant="danger" height={69} textStyle={typography.title} onPress={onConfirm} />
      </View>
    </View>
  );
}
