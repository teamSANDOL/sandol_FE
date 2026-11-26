import { useEffect, useSyncExternalStore } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  DEFAULT_NOTIFICATION_SETTINGS,
  NOTIFICATION_STORAGE_KEYS,
  mergeStored,
  type NotificationKey,
  type NotificationSettings,
} from './notificationSettings';

const KEYS: NotificationKey[] = ['push', 'benefit', 'marketing'];

/** 알림 설정은 마이페이지와 푸시 등록이 함께 보므로 화면 밖 저장소 하나에 둔다 */
let current = DEFAULT_NOTIFICATION_SETTINGS;
let isLoaded = false;
let loading: Promise<void> | null = null;
const listeners = new Set<() => void>();

const emit = () => listeners.forEach((l) => l());
const subscribe = (l: () => void) => {
  listeners.add(l);
  return () => listeners.delete(l);
};

function load(): Promise<void> {
  loading ??= AsyncStorage.multiGet(KEYS.map((k) => NOTIFICATION_STORAGE_KEYS[k]))
    .then((pairs) => {
      const stored = Object.fromEntries(KEYS.map((k, i) => [k, pairs[i]?.[1] ?? null]));
      current = mergeStored(current, stored);
    })
    .catch(() => undefined) // 읽기 실패는 기본값으로 둔다.
    .finally(() => {
      isLoaded = true;
      emit();
    });
  return loading;
}

/** 저장이 실패해도 메모리 상태는 유지되어 화면이 되돌아가지 않는다 */
export function setNotificationSetting(key: NotificationKey, value: boolean): void {
  current = { ...current, [key]: value };
  emit();
  AsyncStorage.setItem(NOTIFICATION_STORAGE_KEYS[key], String(value)).catch(() => undefined);
}

/** 알림 설정 3개와 바꾸는 함수, 저장값을 읽었는지. 기기(AsyncStorage)에 두고 서버에는 푸시 등록 때 함께 보낸다 */
export function useNotificationSettings(): [NotificationSettings, typeof setNotificationSetting, boolean] {
  useEffect(() => {
    void load();
  }, []);
  const settings = useSyncExternalStore(subscribe, () => current);
  const loaded = useSyncExternalStore(subscribe, () => isLoaded);
  return [settings, setNotificationSetting, loaded];
}
