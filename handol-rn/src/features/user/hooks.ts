import { useCallback, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  DEFAULT_NOTIFICATION_SETTINGS,
  NOTIFICATION_STORAGE_KEYS,
  mergeStored,
  type NotificationKey,
  type NotificationSettings,
} from './notificationSettings';

const KEYS: NotificationKey[] = ['push', 'benefit', 'marketing'];

/**
 * 알림 설정 3개. 기기 로컬(AsyncStorage)에만 저장하고 서버로는 보내지 않는다.
 * 저장이 실패해도 메모리 상태는 유지되어 화면이 되돌아가지 않는다.
 */
export function useNotificationSettings(): [NotificationSettings, (key: NotificationKey, value: boolean) => void] {
  const [settings, setSettings] = useState(DEFAULT_NOTIFICATION_SETTINGS);

  useEffect(() => {
    let alive = true;
    AsyncStorage.multiGet(KEYS.map((k) => NOTIFICATION_STORAGE_KEYS[k]))
      .then((pairs) => {
        if (!alive) return;
        const stored = Object.fromEntries(KEYS.map((k, i) => [k, pairs[i]?.[1] ?? null]));
        setSettings((cur) => mergeStored(cur, stored));
      })
      .catch(() => undefined); // 읽기 실패는 기본값으로 둔다.
    return () => {
      alive = false;
    };
  }, []);

  const set = useCallback((key: NotificationKey, value: boolean) => {
    setSettings((cur) => ({ ...cur, [key]: value }));
    AsyncStorage.setItem(NOTIFICATION_STORAGE_KEYS[key], String(value)).catch(() => undefined);
  }, []);

  return [settings, set];
}
