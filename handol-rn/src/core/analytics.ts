import { getAnalytics, logScreenView } from '@react-native-firebase/analytics';

/**
 * 화면 조회를 Firebase Analytics 로 보낸다. 광고 ID 는 모으지 않는다(firebase.json).
 * Firebase 설정 파일 없이 빌드하면 기본 앱이 없어 getAnalytics 가 던지므로 조용히 건너뛴다.
 */
export function trackScreen(path: string): void {
  try {
    logScreenView(getAnalytics(), { screen_name: path, screen_class: path }).catch(() => undefined);
  } catch {
    // Firebase 미설정 빌드
  }
}
