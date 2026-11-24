import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTopBar, GradientScrollView, HandolCard, HPressable, HText, colors, metrics, radius, spacing, typography } from '@/design-system';
import { WithdrawActions } from '../components/WithdrawActions';

export const WITHDRAW_REASONS = [
  '앱 사용이 불편해요',
  '타 앱이 더 편해요(ex. tukorea portal)',
  '쓰지 않는 앱이에요',
  '재가입할 거예요',
  '기타',
] as const;

/**
 * 회원탈퇴 1단계: 이유 선택 (Figma 2196:800).
 * 이유를 고르면 그 아래 자유 의견 칸이 펼쳐진다. 이유를 받는 API가 아직 없어 선택 내용은 저장하지 않는다.
 */
export default function WithdrawReasonScreen() {
  const [selected, setSelected] = useState<number | null>(null);
  const [comment, setComment] = useState('');
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar title="회원탈퇴" titleNode={<HText variant="title">회원탈퇴</HText>} onBack={() => router.back()} showUser={false} horizontalPadding={metrics.pageGutter - 10} />
      <GradientScrollView
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingHorizontal: metrics.pageGutter, paddingBottom: spacing.xl + insets.bottom }}
      >
        <View style={{ paddingLeft: 11 }}>
          <HText variant="headline" keepAll>
            탈퇴하는 이유를 알려주세요
          </HText>
        </View>
        <View style={{ height: 27 }} />
        {WITHDRAW_REASONS.map((label, i) => (
          <ReasonOption key={label} label={label} selected={selected === i} onPress={() => setSelected(i)}>
            {selected === i && <CommentField value={comment} onChange={setComment} />}
          </ReasonOption>
        ))}
        <View style={{ height: 11 }} />
        <WithdrawActions
          confirmLabel="다음 단계로"
          onContinue={() => router.back()}
          onConfirm={selected === null ? undefined : () => router.push('/user/withdraw/confirm')}
        />
      </GradientScrollView>
    </View>
  );
}

/** 라디오 한 줄. 선택되면 테두리와 점이 primary, 글씨가 굵어진다. */
function ReasonOption({ label, selected, onPress, children }: { label: string; selected: boolean; onPress: () => void; children?: React.ReactNode }) {
  return (
    <View>
      <View style={styles.clip}>
        <HPressable accessibilityRole="radio" accessibilityState={{ selected }} onPress={onPress} style={styles.option}>
          <View style={[styles.radio, { borderColor: selected ? colors.primary : colors.border }]}>
            {selected && <View style={styles.dot} />}
          </View>
          <View style={{ flex: 1 }}>
            <HText variant="body" weight={selected ? 'bold' : undefined} tone={selected ? undefined : 'muted'} keepAll>
              {label}
            </HText>
          </View>
        </HPressable>
      </View>
      {children ? <View style={{ paddingBottom: 8 }}>{children}</View> : null}
    </View>
  );
}

/** 자유 의견 (2196:1131) */
function CommentField({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <HandolCard contentStyle={{ paddingLeft: 44, paddingRight: metrics.cardInset, paddingVertical: 17 }}>
      <TextInput
        value={value}
        onChangeText={onChange}
        multiline
        textAlignVertical="top"
        style={styles.comment}
        placeholder="더 나은 한돌이가 될 수 있도록 의견을 들려주세요."
        placeholderTextColor={colors.muted}
        accessibilityLabel="탈퇴 의견"
      />
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  option: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 12 },
  radio: { width: 24, height: 24, borderRadius: 12, borderWidth: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
  dot: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.primary },
  comment: {
    padding: 0,
    minHeight: 54,
    maxHeight: 100,
    fontFamily: typography.caption.fontFamily,
    fontSize: typography.caption.fontSize,
    color: colors.text,
  },
});
