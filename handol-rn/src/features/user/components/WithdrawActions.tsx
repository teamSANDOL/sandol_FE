import { View } from 'react-native';
import { HandolButton, spacing, typography } from '@/design-system';

/** 좁은 화면에서 버튼 안쪽 여백 16 때문에 '계속 사용하기'(116)가 두 줄이 되지 않게 글자 상자를 양쪽 6씩 넓힌다 (시안 2:6299 는 안쪽 22) */
const BUTTON_TEXT = { ...typography.title, marginHorizontal: -6 };

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
        <HandolButton label="계속 사용하기" variant="primary" hasBorder height={69} textStyle={BUTTON_TEXT} onPress={onContinue} />
      </View>
      <View style={{ flex: 1 }}>
        <HandolButton label={confirmLabel} variant="danger" height={69} textStyle={BUTTON_TEXT} onPress={onConfirm} />
      </View>
    </View>
  );
}
