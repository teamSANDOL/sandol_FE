import { Linking } from 'react-native';
import { openExternalLink } from '@/core/utils/externalLink';

/** 도보 길찾기. 네이버 지도 앱이 있으면 앱으로, 없으면 카카오맵 웹 길찾기로 연다. */
export async function openDirections(name: string, latitude: number, longitude: number): Promise<void> {
  const label = encodeURIComponent(name);
  try {
    await Linking.openURL(`nmap://route/walk?dlat=${latitude}&dlng=${longitude}&dname=${label}&appname=app.handol.student`);
    return;
  } catch {
    // 앱이 없으면 웹으로 넘어간다.
  }
  await openExternalLink(`https://map.kakao.com/link/to/${label},${latitude},${longitude}`);
}
