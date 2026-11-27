import { useState } from 'react';
import { Linking, View } from 'react-native';
import * as Application from 'expo-application';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTopBar, BarIconButton, GradientScrollView, Icon, colors, metrics, showComingSoon, showToast, spacing, TOAST_LONG_MS } from '@/design-system';
import { useAuth } from '@/core/auth/AuthProvider';
import { useResetTo } from '@/features/auth/navigation';
import { displayId } from '@/core/auth/session';
import { BlockingOverlay, ConfirmDialog } from '../components/ConfirmDialog';
import { LoginCard, ProfileCard } from '../components/UserHeaderCards';
import { LinkRow, Section, ToggleRow } from '../components/UserRows';
import { ensurePushPermission } from '@/features/push/pushService';
import { useNotificationSettings } from '../hooks';

/** 상단 바 아래 첫 카드까지: 시안 카드 y133 - 시안 상단 바 끝 82 (2:6112) */
const TOP_GAP = 51;

/**
 * 마이페이지 (Figma 2158:997).
 * 로그인 상태면 프로필 카드와 오른쪽 위 로그아웃, 둘러보기(비로그인)면 '로그인하기' 카드(2195:462).
 * 알림 토글은 기기에 저장하고 푸시 기기 등록 때 서버에 함께 보낸다. 푸시를 켜면 알림 권한을 묻는다.
 */
export default function UserScreen() {
  const { session, logout } = useAuth();
  const insets = useSafeAreaInsets();
  const [settings, setSetting] = useNotificationSettings();
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);
  const version = Application.nativeApplicationVersion;
  const resetTo = useResetTo();

  const handlePush = async (on: boolean) => {
    if (!on) return setSetting('push', false);
    const permission = await ensurePushPermission().catch(() => 'denied' as const);
    if (permission === 'granted') return setSetting('push', true);
    showToast('휴대폰 설정에서 한돌이 알림을 허용해 주세요', TOAST_LONG_MS);
    if (permission === 'blocked') void Linking.openSettings();
  };

  // 광고성 정보 수신 동의·철회는 처리 결과(일자)를 알려야 한다(정보통신망법 제50조 제7·8항).
  const handleConsent = (key: 'benefit' | 'marketing', label: string, on: boolean) => {
    setSetting(key, on);
    showToast(`${new Date().toLocaleDateString('ko-KR')} ${label} 수신 ${on ? '동의' : '거부'} 처리되었습니다`, TOAST_LONG_MS);
  };

  const handleLogout = async () => {
    setConfirming(false);
    setBusy(true);
    try {
      await logout();
      resetTo('login');
    } catch {
      showToast('로그아웃에 실패했습니다', TOAST_LONG_MS);
    } finally {
      setBusy(false);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar
        title="마이페이지"
        onBack={() => router.back()}
        showUser={false}
        horizontalPadding={metrics.pageGutter - 10}
        trailing={
          session ? (
            <BarIconButton label="로그아웃" onPress={() => setConfirming(true)}>
              <Icon name="myLogout" />
            </BarIconButton>
          ) : undefined
        }
      />
      <GradientScrollView
        contentContainerStyle={{
          paddingHorizontal: metrics.pageGutter,
          paddingTop: TOP_GAP,
          paddingBottom: spacing.xl + insets.bottom,
        }}
      >
        {/* 프로필 카드 아래 14(2:6148→2:6113), 섹션 사이 16 */}
        {session ? (
          <ProfileCard name={displayId(session)} email={session.email ?? session.username ?? ''} />
        ) : (
          <LoginCard onPress={() => resetTo('login')} />
        )}
        <View style={{ height: 14 }} />
        <Section label="알림 설정" paddingTop={15} paddingBottom={21}>
          <ToggleRow icon="myBell" label="푸시 알림" value={settings.push} onChange={(v) => void handlePush(v)} />
          <ToggleRow icon="myGift" label="혜택 • 이벤트 알림" value={settings.benefit} onChange={(v) => handleConsent('benefit', '혜택·이벤트 알림', v)} />
          <ToggleRow icon="myMegaphone" label="마케팅 정보 수신" value={settings.marketing} onChange={(v) => handleConsent('marketing', '마케팅 정보', v)} />
        </Section>
        <View style={{ height: spacing.md }} />
        <Section label="고객 지원">
          <LinkRow icon="myNotice" label="공지사항" chevronColor={colors.border} onPress={() => router.push('/user/announcements')} />
          <LinkRow icon="myFaq" label="자주 묻는 질문" chevronColor={colors.border} onPress={() => router.push('/user/faq')} />
          <LinkRow icon="myInquiry" label="1:1 문의" chevronColor={colors.border} onPress={showComingSoon} />
          <LinkRow icon="myInfo" label="서비스 안내" chevronColor={colors.border} onPress={() => router.push('/user/guide')} />
        </Section>
        <View style={{ height: spacing.md }} />
        <Section label="기타">
          <LinkRow icon="myTerms" label="약관 및 정책" chevronColor={colors.text20} onPress={() => router.push('/user/policy/terms')} />
          <LinkRow icon="myTerms" label="개인정보처리방침" chevronColor={colors.text20} onPress={() => router.push('/user/policy/privacy')} />
          <LinkRow icon="myVersion" label="앱 버전" trailingText={version ? `v${version}` : ''} />
          {/* 비로그인(게스트)에게는 지울 계정이 없다. */}
          {session && <LinkRow icon="myLeave" label="회원탈퇴" danger chevronColor={colors.text20} onPress={() => router.push('/user/withdraw')} />}
        </Section>
      </GradientScrollView>
      <ConfirmDialog
        visible={confirming}
        icon="logout"
        title="로그아웃"
        message={'정말 로그아웃하시겠어요?\n언제든 다시 로그인할 수 있어요.'}
        confirmLabel="로그아웃"
        onConfirm={() => void handleLogout()}
        onCancel={() => setConfirming(false)}
      />
      <BlockingOverlay visible={busy} />
    </View>
  );
}
