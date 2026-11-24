import { Platform, ToastAndroid, Alert } from 'react-native';

/** 짧은 안내 (Flutter floating SnackBar 대응) */
export function showToast(message: string): void {
  if (Platform.OS === 'android') {
    ToastAndroid.show(message, ToastAndroid.SHORT);
  } else {
    Alert.alert(message);
  }
}

/** 아직 구현되지 않은 기능을 눌렀을 때 */
export function showComingSoon(): void {
  showToast('준비중입니다');
}
