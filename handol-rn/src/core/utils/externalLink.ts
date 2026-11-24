import { Linking } from 'react-native';
import { showToast } from '@/design-system/components/toast';

const SAFE_SCHEMES = ['http:', 'https:', 'tel:', 'mailto:'];

/** 외부 앱(브라우저 · 전화 · 메일)으로 링크를 연다. 실패하면 토스트로 알린다. */
export async function openExternalLink(url: string): Promise<boolean> {
  try {
    const scheme = url.slice(0, url.indexOf(':') + 1).toLowerCase();
    if (!SAFE_SCHEMES.includes(scheme)) throw new Error('unsupported scheme');
    await Linking.openURL(url);
    return true;
  } catch {
    showToast('링크를 열 수 없습니다');
    return false;
  }
}
