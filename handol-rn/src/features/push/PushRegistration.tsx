import { useEffect, useSyncExternalStore } from 'react';
import { useAuth } from '@/core/auth/AuthProvider';
import { useNotificationSettings } from '../user/hooks';
import { pushToken, registerPushDevice } from './pushService';

/** 토큰·로그인 상태·알림 설정이 바뀔 때마다 서버에 기기를 다시 등록한다. 화면에는 아무것도 그리지 않는다 */
export function PushRegistration() {
  const { status } = useAuth();
  const [settings, , isLoaded] = useNotificationSettings();
  const token = useSyncExternalStore(pushToken.subscribe, pushToken.get);

  useEffect(() => {
    if (!token || !isLoaded || status === 'restoring') return;
    // ponytail: 실패하면 다음 변경·실행 때 다시 보낸다. 재시도 큐는 서버가 생긴 뒤 필요하면 둔다.
    registerPushDevice(token, settings).catch(() => undefined);
  }, [token, isLoaded, status, settings]);

  return null;
}
