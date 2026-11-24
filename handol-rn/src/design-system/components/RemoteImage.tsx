import { useState } from 'react';
import { View, type StyleProp, type ImageStyle } from 'react-native';
import { Image, type ImageContentFit } from 'expo-image';
import { colors } from '../tokens';

type Props = {
  url?: string | null;
  /** 서버 이미지가 없거나 못 받으면 쓰는 앱 에셋 (require 모듈) */
  asset?: number;
  contentFit?: ImageContentFit;
  style?: StyleProp<ImageStyle>;
  accessibilityLabel?: string;
};

/**
 * 서버 이미지가 있으면 그것을, 없거나 받지 못하면 앱 에셋, 에셋도 없으면 primarySoft 칸 (RemoteImage).
 * 디스크 캐시는 expo-image 가 한다.
 */
export function RemoteImage({ url, asset, contentFit = 'cover', style, accessibilityLabel }: Props) {
  const [hasFailed, setHasFailed] = useState(false);
  const remote = url && !hasFailed ? { uri: url } : undefined;
  const source = remote ?? asset;
  if (source === undefined) {
    return <View style={[{ backgroundColor: colors.primarySoft }, style as object]} />;
  }
  return (
    <Image
      source={source}
      contentFit={contentFit}
      style={[{ backgroundColor: colors.primarySoft }, style]}
      onError={() => setHasFailed(true)}
      transition={120}
      accessibilityLabel={accessibilityLabel}
    />
  );
}
