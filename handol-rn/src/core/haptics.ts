import { requireOptionalNativeModule } from 'expo-modules-core';

/**
 * 햅틱. expo-haptics 네이티브 모듈은 0.3.23 설치 파일부터 들어 있다. 그 전 설치 파일(0.3.21·0.3.22)도
 * 같은 JS 번들을 OTA 로 받으므로, 모듈이 없으면 import 만으로 앱이 죽지 않게 있을 때만 불러온다.
 */
const Haptics: typeof import('expo-haptics') | null = requireOptionalNativeModule('ExpoHaptics')
  ? // eslint-disable-next-line @typescript-eslint/no-require-imports
    require('expo-haptics')
  : null;

/** 선택이 바뀔 때 (Flutter HapticFeedback.selectionClick) */
export function hapticSelection(): void {
  void Haptics?.selectionAsync().catch(() => undefined);
}

/** 길게 눌러 복사 등 (Flutter HapticFeedback.mediumImpact) */
export function hapticMedium(): void {
  void Haptics?.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => undefined);
}
