import { Linking } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import { openExternalLink } from '@/core/utils/externalLink';
import { showToast } from '@/design-system';

/** 전화 앱(다이얼러)을 연다. 다이얼러가 없는 기기는 번호를 복사해 알린다. */
export async function dial(phone: string): Promise<void> {
  const digits = phone.replace(/[^\d+]/g, '');
  try {
    await Linking.openURL(`tel:${digits}`);
  } catch {
    await Clipboard.setStringAsync(digits).catch(() => undefined);
    showToast('전화 앱을 열 수 없어 번호를 복사했습니다');
  }
}

export async function openUrl(url: string): Promise<void> {
  await openExternalLink(url.trim());
}

/** 길게 누름: 클립보드 복사 + 토스트 */
export async function copyText(text: string, label = '내용'): Promise<void> {
  try {
    await Clipboard.setStringAsync(text);
    showToast(`${label}을(를) 복사했습니다`);
  } catch {
    showToast(`${label}을(를) 복사할 수 없습니다`);
  }
}
