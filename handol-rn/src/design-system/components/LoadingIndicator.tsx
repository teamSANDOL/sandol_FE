import { View } from 'react-native';
import LottieView from 'lottie-react-native';
import { lottie } from '../assets';

/** 앱 공용 로딩 인디케이터 (handol_loading.json) */
export function LoadingIndicator({ size = 64 }: { size?: number }) {
  return (
    <View accessible accessibilityLabel="불러오는 중" accessibilityRole="progressbar">
      <LottieView source={lottie.loading} autoPlay loop style={{ width: size, height: size }} />
    </View>
  );
}
