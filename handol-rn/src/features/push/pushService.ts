import { Platform } from 'react-native';
import * as Application from 'expo-application';
import * as Notifications from 'expo-notifications';
import { router } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '@/core/api/client';
import { env } from '@/core/env';
import { rememberNotice } from '../notice/api';
import type { NotificationSettings } from '../user/notificationSettings';
import { pushTargetFrom, type PushTarget } from './pushTarget';

/** Flutter 앱·서버 payload 와 같은 기본 채널 (app.config.js expo-notifications defaultChannel) */
const CHANNEL_ID = 'sandol_default';
const ASKED_KEY = 'push.permissionAsked';

let token: string | null = null;
const tokenListeners = new Set<() => void>();
/** 탭 화면이 뜨기 전(스플래시·로그인)에 누른 알림. 탭이 뜨면 연다 */
let pending: PushTarget | null = null;
let isRouterReady = false;
let isStarted = false;
const handled = new Set<string>();

/** 기기 FCM 등록 토큰(Android·iOS 공통). 아직 없으면 null */
export const pushToken = {
  get: (): string | null => token,
  subscribe: (listener: () => void): (() => void) => {
    tokenListeners.add(listener);
    return () => tokenListeners.delete(listener);
  },
};

function setToken(next: string): void {
  if (!next || next === token) return;
  token = next;
  // 개발 빌드에서만: Firebase 콘솔 테스트 메시지·scripts/send-test-push.mjs 에 넣을 토큰
  if (__DEV__) console.log('[push] device token', next);
  tokenListeners.forEach((l) => l());
}

function open(target: PushTarget | null): void {
  if (!target) return;
  if (!isRouterReady) {
    pending = target;
    return;
  }
  if (target.notice) rememberNotice(target.notice);
  // 탭 스택에 상세 하나만 쌓인다. 뒤로가기는 탭 셸이 그 탭 첫 화면(목록)으로 돌린다((tabs)/_layout).
  router.navigate(target.href);
}

function openResponse(response: Notifications.NotificationResponse | null): void {
  if (!response) return;
  // 실행을 일으킨 알림은 getLastNotificationResponse 와 리스너 양쪽에서 올 수 있다
  const id = response.notification.request.identifier;
  if (handled.has(id)) return;
  handled.add(id);
  open(pushTargetFrom(response.notification.request.content.data));
}

/**
 * 앱 시작 시 한 번. Firebase 설정 파일 없이 빌드했거나 토큰 발급이 실패해도 던지지 않고,
 * 받은 알림 표시·탭 이동만 하고 서버 등록은 건너뛴다.
 */
export function startPush(): void {
  if (isStarted) return;
  isStarted = true;
  Notifications.setNotificationHandler({
    handleNotification: async () => ({ shouldShowBanner: true, shouldShowList: true, shouldPlaySound: true, shouldSetBadge: false }),
  });
  Notifications.addNotificationResponseReceivedListener(openResponse);
  openResponse(Notifications.getLastNotificationResponse());
  void (async () => {
    try {
      if (Platform.OS === 'ios') {
        await startIosFcmToken();
        return;
      }
      Notifications.addPushTokenListener((t) => setToken(String(t.data)));
      await Notifications.setNotificationChannelAsync(CHANNEL_ID, { name: '한돌이 알림', importance: Notifications.AndroidImportance.HIGH });
      // Android 의 기기 토큰이 곧 FCM 등록 토큰이다
      setToken(String((await Notifications.getDevicePushTokenAsync()).data));
    } catch (e) {
      if (__DEV__) console.warn('[push] 토큰 없이 계속합니다', e);
    }
  })();
}

/**
 * iOS 기기 토큰은 APNs 토큰이라 FCM 으로 보낼 수 없다. Firebase Messaging 으로 FCM 토큰을 받는다
 * (Firebase 가 APNs 토큰과 묶는다). 표시·탭 처리는 Android 와 같이 expo-notifications 가 한다.
 * Android 에는 이 모듈을 링크하지 않는다(react-native.config.js): expo-notifications 의 수신 서비스와 겹친다.
 */
async function startIosFcmToken(): Promise<void> {
  const { getMessaging, getToken, onTokenRefresh } = await import('@react-native-firebase/messaging');
  const messaging = getMessaging();
  onTokenRefresh(messaging, setToken);
  setToken(await getToken(messaging));
}

/** 스플래시가 로그인으로 넘어갈 때 부른다. 종료 상태에서 누른 알림은 로그인 뒤에 열지 않는다 (Flutter splash) */
export function discardPendingPush(): void {
  pending = null;
}

/** 탭 화면이 뜨고 내려갈 때 부른다. 뜨면 미뤄 둔 알림을 연다 */
export function setPushRouterReady(isReady: boolean): void {
  isRouterReady = isReady;
  if (!isReady) return;
  const target = pending;
  pending = null;
  open(target);
}

export type PushPermission = 'granted' | 'denied' | 'blocked';

/** 알림 권한을 확인하고, 물어볼 수 있으면 묻는다. blocked 는 기기 설정에서만 바꿀 수 있다 */
export async function ensurePushPermission(): Promise<PushPermission> {
  const current = await Notifications.getPermissionsAsync();
  if (current.granted) return 'granted';
  if (!current.canAskAgain) return 'blocked';
  return (await Notifications.requestPermissionsAsync()).granted ? 'granted' : 'denied';
}

/** 처음 한 번만 권한을 묻는다. 이미 물었으면 null */
export async function askPushPermissionOnce(): Promise<PushPermission | null> {
  if (await AsyncStorage.getItem(ASKED_KEY)) return null;
  await AsyncStorage.setItem(ASKED_KEY, '1');
  return ensurePushPermission();
}

/**
 * 기기 등록·갱신 (BFF 요청서 7장). 로그인 중이면 api 가 Authorization 을 붙여 서버가 사용자와 묶고,
 * 로그아웃 뒤 다시 부르면 인증 없이 가서 묶음이 풀린다.
 */
export function registerPushDevice(deviceToken: string, preferences: NotificationSettings): Promise<unknown> {
  return api.put(`${env.bffBaseUrl}/app/v1/push/devices`, {
    token: deviceToken,
    platform: Platform.OS,
    token_type: 'fcm',
    app_version: Application.nativeApplicationVersion,
    build: Number(Application.nativeBuildVersion) || null,
    preferences,
  });
}
