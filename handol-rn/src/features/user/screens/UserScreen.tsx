import { useState } from 'react';
import { View } from 'react-native';
import * as Application from 'expo-application';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTopBar, BarIconButton, GradientScrollView, Icon, colors, metrics, showComingSoon, showToast, spacing } from '@/design-system';
import { useAuth } from '@/core/auth/AuthProvider';
import { displayId } from '@/core/auth/session';
import { BlockingOverlay, ConfirmDialog } from '../components/ConfirmDialog';
import { LoginCard, ProfileCard } from '../components/UserHeaderCards';
import { LinkRow, Section, ToggleRow } from '../components/UserRows';
import { useNotificationSettings } from '../hooks';

/**
 * 마이페이지 (Figma 2158:997).
 * 로그인 상태면 프로필 카드와 오른쪽 위 로그아웃, 둘러보기(비로그인)면 '로그인하기' 카드(2195:462).
 * 알림 토글은 서버 연동 전이라 기기에만 저장한다.
 */
export default function UserScreen() {
  const { session, logout } = useAuth();
  const insets = useSafeAreaInsets();
  const [settings, setSetting] = useNotificationSettings();
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);
  const version = Application.nativeApplicationVersion;

  const handleLogout = async () => {
    setConfirming(false);
    setBusy(true);
    try {
      await logout();
      router.replace('/login');
    } catch {
      showToast('로그아웃에 실패했습니다');
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
          paddingTop: spacing.md,
          paddingBottom: spacing.xl + insets.bottom,
        }}
      >
        {/* 프로필 · 로그인 카드 아래는 16, 섹션 사이는 24 */}
        {session ? (
          <ProfileCard name={displayId(session)} email={session.email ?? session.username ?? ''} />
        ) : (
          <LoginCard onPress={() => router.push('/login')} />
        )}
        <View style={{ height: spacing.md }} />
        <Section label="알림 설정">
          <ToggleRow icon="myBell" label="푸시 알림" value={settings.push} onChange={(v) => setSetting('push', v)} />
          <ToggleRow icon="myGift" label="혜택 • 이벤트 알림" value={settings.benefit} onChange={(v) => setSetting('benefit', v)} />
          <ToggleRow icon="myMegaphone" label="마케팅 정보 수신" value={settings.marketing} onChange={(v) => setSetting('marketing', v)} />
        </Section>
        <View style={{ height: spacing.lg }} />
        <Section label="고객 지원">
          <LinkRow icon="myNotice" label="공지사항" onPress={() => router.navigate('/notice')} />
          <LinkRow icon="myFaq" label="자주 묻는 질문" onPress={showComingSoon} />
          <LinkRow icon="myInquiry" label="1:1 문의" onPress={showComingSoon} />
          <LinkRow icon="myInfo" label="서비스 안내" onPress={showComingSoon} />
        </Section>
        <View style={{ height: spacing.lg }} />
        <Section label="기타">
          <LinkRow icon="myTerms" label="약관 및 정책" onPress={() => router.push('/user/policy/terms')} />
          <LinkRow icon="myTerms" label="개인정보처리방침" onPress={() => router.push('/user/policy/privacy')} />
          <LinkRow icon="myVersion" label="앱 버전" trailingText={version ? `v${version}` : ''} />
          {/* 비로그인(게스트)에게는 지울 계정이 없다. */}
          {session && <LinkRow icon="myLeave" label="회원탈퇴" danger onPress={() => router.push('/user/withdraw')} />}
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
