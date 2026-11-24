export type NotificationSettings = { push: boolean; benefit: boolean; marketing: boolean };
export type NotificationKey = keyof NotificationSettings;

export const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettings = { push: true, benefit: true, marketing: false };

export const NOTIFICATION_STORAGE_KEYS: Record<NotificationKey, string> = {
  push: 'notification.push',
  benefit: 'notification.benefit',
  marketing: 'notification.marketing',
};

/** 저장된 값이 없는 항목은 지금 값(기본값 또는 읽는 동안 바꾼 값)을 둔다. */
export function mergeStored(current: NotificationSettings, stored: Partial<Record<NotificationKey, string | null>>): NotificationSettings {
  const pick = (k: NotificationKey) => (stored[k] == null ? current[k] : stored[k] === 'true');
  return { push: pick('push'), benefit: pick('benefit'), marketing: pick('marketing') };
}
