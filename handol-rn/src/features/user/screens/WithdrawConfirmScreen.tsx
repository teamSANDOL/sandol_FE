import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  AppTopBar,
  GradientScrollView,
  HandolCard,
  HandolCheckbox,
  HandolIconLabel,
  HText,
  Icon,
  colors,
  metrics,
  showToast,
  spacing,
  TOAST_LONG_MS,
} from '@/design-system';
import { useAuth } from '@/core/auth/AuthProvider';
import { useResetTo } from '@/features/auth/navigation';
import { BlockingOverlay, ConfirmDialog } from '../components/ConfirmDialog';
import { WithdrawActions } from '../components/WithdrawActions';
import { userTheme } from '../theme';

const BRAND = '한돌이';
const NOTICE_ITEMS: { text: string; red: boolean }[] = [
  { text: '회원탈퇴 시 한돌이의 모든 서비스 이용 내역 및 개인 계정 정보가 즉시 파기되며, 어떠한 경우에도 영구적으로 복구할 수 없습니다.', red: false },
  { text: '무분별한 탈퇴 및 재가입 방지를 위해 탈퇴 후 30일 동안 동일한 계정 정보로 다시 가입할 수 없습니다.', red: true },
  { text: '단, 관련 법령에 따라 보존할 의무가 있는 결제 및 주요 서비스 이용 기록은 정해진 기간 동안 안전하게 보관된 후 파기됩니다.', red: false },
];

/**
 * 회원탈퇴 2단계: 최종 확인 (Figma 2196:951).
 * 유의사항에 동의해야 '회원 탈퇴하기'가 켜진다. 실제 계정 삭제이며 끝나면 로그인 화면으로 보낸다.
 */
export default function WithdrawConfirmScreen() {
  const { deleteAccount } = useAuth();
  const insets = useSafeAreaInsets();
  const [agreed, setAgreed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState(false);
  const resetTo = useResetTo();

  const handleDelete = async () => {
    setBusy(true);
    try {
      await deleteAccount();
      showToast('회원 탈퇴가 완료되었습니다', TOAST_LONG_MS);
      resetTo('login');
    } catch {
      setFailed(true);
    } finally {
      setBusy(false);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar title="회원탈퇴" titleNode={<HText variant="title">회원탈퇴</HText>} onBack={() => router.back()} showUser={false} horizontalPadding={metrics.pageGutter - 10} />
      <GradientScrollView contentContainerStyle={{ paddingTop: 53, paddingBottom: spacing.xl + insets.bottom }}>
        <View style={{ paddingHorizontal: metrics.pageGutter }}>
          <FarewellCard />
        </View>
        <View style={{ height: 7 }} />
        <HText variant="body" keepAll style={{ textAlign: 'center' }}>
          {'조금 더 함께하고 싶지만,\n아쉬운 마음으로 보내드릴게요. 언제든 다시 찾아주세요!'}
        </HText>
        <View style={{ height: 69 }} />
        <NoticeBlock />
        {/* 띠 아래 9 - 체크박스 터치 여백 6 */}
        <View style={{ height: 3 }} />
        <View style={{ paddingHorizontal: metrics.pageGutter }}>
          <HandolCheckbox isDense label="위 내용을 숙지하였으며 탈퇴에 동의합니다." isChecked={agreed} onChange={setAgreed} />
          <View style={{ height: 5 }} />
          {/* 두 단계 모두 '계속 사용하기'는 마이페이지로 돌아간다. */}
          <WithdrawActions confirmLabel="회원 탈퇴하기" onContinue={() => router.dismissTo('/user')} onConfirm={agreed ? () => void handleDelete() : undefined} />
        </View>
      </GradientScrollView>
      <ConfirmDialog
        visible={failed}
        icon="error"
        title="탈퇴 실패"
        message={'계정 삭제 요청이 실패했습니다.\n잠시 후 다시 시도하거나 관리자에게 문의해 주세요.'}
        confirmLabel="확인"
        showCancel={false}
        onConfirm={() => setFailed(false)}
        onCancel={() => setFailed(false)}
      />
      <BlockingOverlay visible={busy} />
    </View>
  );
}

/** 진회색 카드 + 우는 한돌이 (2196:676) */
function FarewellCard() {
  return (
    <HandolCard color={colors.textSecondary} contentStyle={{ paddingLeft: 20, paddingRight: 20, paddingTop: 21, paddingBottom: 22, alignItems: 'center', gap: 9 }}>
      <HText variant="title" tone="onPrimary">
        정말로 떠나실 건가요?
      </HText>
      <Icon name="myWithdrawMascot" />
    </HandolCard>
  );
}

/** 시안은 서비스 이름을 빨간 굵은 글씨로 강조한다 (2:6337) */
function highlight(text: string) {
  const [head, ...rest] = text.split(BRAND);
  if (rest.length === 0) return text;
  return [
    head,
    <HText key="brand" variant="caption" weight="bold" tone="danger" style={styles.notice}>
      {BRAND}
    </HText>,
    rest.join(BRAND),
  ];
}

/** 회색 띠 안의 유의사항 (2196:1183). 두 번째 항목은 빨간 글씨. */
function NoticeBlock() {
  return (
    <View style={styles.band}>
      <HandolIconLabel icon={<Icon name="myNoticeInfo" />} label="꼭 확인해주세요!" variant="body" weight="bold" tone="accent" />
      {/* alignSelf: 띠가 flex-start 라 늘리지 않으면 글 상자 폭이 0 이 되어 글이 안 보인다 */}
      <View style={{ gap: spacing.md, alignSelf: 'stretch' }}>
        {NOTICE_ITEMS.map(({ text, red }) => (
          <View key={text} style={{ flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm }}>
            <HText variant="caption" tone={red ? 'danger' : undefined} style={styles.notice}>
              •
            </HText>
            <View style={{ flex: 1 }}>
              <HText variant="caption" tone={red ? 'danger' : undefined} keepAll style={styles.notice}>
                {highlight(text)}
              </HText>
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  band: { backgroundColor: userTheme.noticeBand, paddingHorizontal: metrics.pageGutter, paddingTop: 29, paddingBottom: 40, gap: 35, alignItems: 'flex-start' },
  notice: { lineHeight: 18, letterSpacing: -1 },
});
