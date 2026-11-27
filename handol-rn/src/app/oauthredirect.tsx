import { useEffect } from 'react';
import { router } from 'expo-router';

/**
 * Keycloak 로그인 딥링크(app.handol.student://oauthredirect, 0.3.23 까지는 kr.sandori.handori)가 라우터로 들어왔을 때.
 * 코드 교환은 expo-auth-session 이 하므로 여기서는 원래 화면으로 돌아가기만 한다.
 */
export default function OAuthRedirect() {
  useEffect(() => {
    if (router.canGoBack()) router.back();
    else router.replace('/');
  }, []);
  return null;
}
