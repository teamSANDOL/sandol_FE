export type NotificationSettings = { push: boolean; benefit: boolean; marketing: boolean };
export type NotificationKey = keyof NotificationSettings;

/** 혜택·마케팅은 광고성 정보라 동의 전에는 꺼 둔다(정보통신망법 제50조, 사전 동의) */
export const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettings = { push: true, benefit: false, marketing: false };

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
