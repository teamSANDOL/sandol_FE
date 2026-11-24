import { useEffect, useState } from 'react';
import { Dimensions, View } from 'react-native';
import { router } from 'expo-router';
import { useAuth } from '@/core/auth/AuthProvider';
import { colors, HandolButton, HandolCheckbox, HText, showToast, spacing, typography } from '@/design-system';
import { AuthBrandHeading, AuthDivider } from '../components/AuthParts';
import { AuthScaffold } from '../components/AuthScaffold';
import { SignUpLink, SocialRow, TextAction } from '../components/LoginActions';
import { loginTopOffset } from '../layout';

// HandolButton 이 typography.button 의 글자색(text)을 덮어써 흰 글씨가 검게 나오므로 색을 명시한다
const BUTTON_TEXT = { ...typography.button, color: colors.background };
const LOGIN_FAILED = '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.';

/**
 * 로그인 시작 화면. 아이디·비밀번호는 앱에서 받지 않는다 — 로그인과
 * 회원가입은 모두 시스템 브라우저의 Keycloak 화면에서 한다.
 */
export default function LoginScreen() {
  const { session, isLoggingIn, error, login, logout, continueAsGuest } = useAuth();
  // Flutter MediaQuery 높이는 엣지-투-엣지에서 화면 전체 높이다(window 는 내비게이션 바만큼 짧을 수 있다)
  const height = Dimensions.get('screen').height;
  const [rememberMe, setRememberMe] = useState(true);

  useEffect(() => {
    if (error) showToast(LOGIN_FAILED);
  }, [error]);

  const handleLogin = async (opts: { useKakao?: boolean; signUp?: boolean } = {}) => {
    const isSuccess = await login({ ...opts, rememberMe });
    if (isSuccess) router.replace('/home');
  };

  /** 둘러보기를 고른 시각을 남기고(7일간 시작 때 로그인 화면 생략) 홈으로 간다 */
  const handleBrowse = async () => {
    await continueAsGuest();
    router.replace('/home');
  };

  return (
    <AuthScaffold top={loginTopOffset(height)}>
      <AuthBrandHeading>
        {'로그인하고 더 '}
        <HText variant="title" tone="accent">
          {'똑똑한\n학교생활'}
        </HText>
        {'을 시작해요'}
      </AuthBrandHeading>
      <View style={{ height: 92 }} />
      {session === null ? (
        <>
          <SocialRow
            isBusy={isLoggingIn}
            onKakao={() => void handleLogin({ useKakao: true })}
            onGoogle={() => showToast('Google 로그인은 준비 중이에요.')}
            onApple={() => showToast('Apple 로그인은 준비 중이에요.')}
          />
          <View style={{ height: 10 }} />
          <AuthDivider label="또는" />
          <View style={{ height: spacing.sm }} />
          <HandolButton label="아이디로 시작하기" isLoading={isLoggingIn} onPress={() => void handleLogin()} textStyle={BUTTON_TEXT} />
          <View style={{ height: 6 }} />
          <HandolCheckbox label="로그인 상태 유지" isChecked={rememberMe} onChange={setRememberMe} />
          <HText variant="caption" tone="muted">
            {rememberMe ? '앱을 다시 열어도 로그인이 유지돼요.' : '앱을 완전히 종료하면 로그아웃돼요.'}
          </HText>
          <View style={{ height: 12 }} />
          <SignUpLink onPress={isLoggingIn ? undefined : () => void handleLogin({ signUp: true })} />
          <TextAction label="로그인 없이 둘러보기" onPress={isLoggingIn ? undefined : () => void handleBrowse()} />
        </>
      ) : (
        <>
          <HandolButton label="홈으로 가기" onPress={() => router.replace('/home')} textStyle={BUTTON_TEXT} />
          <View style={{ height: 12 }} />
          <TextAction label="로그아웃" onPress={() => void logout()} />
        </>
      )}
    </AuthScaffold>
  );
}
