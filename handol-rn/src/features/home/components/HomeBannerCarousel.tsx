import { useState } from 'react';
import { FlatList, View, type LayoutChangeEvent, type NativeScrollEvent, type NativeSyntheticEvent } from 'react-native';
import { spacing } from '@/design-system';
import type { HomeBanner } from '../model';
import { BannerDots } from './BannerDots';
import { HomeBannerCard } from './HomeBannerCard';

/** 345×138 (Figma 홈_re 2890:2393 의 2901:1129) */
const ASPECT_RATIO = 345 / 138;

/** 홈 맨 위 배너 자리. 옆으로 넘겨 여러 장을 본다. 한 장뿐이면 점 표시가 없다 */
export function HomeBannerCarousel({ banners }: { banners: readonly HomeBanner[] }) {
  const [width, setWidth] = useState(0);
  const [page, setPage] = useState(0);
  if (banners.length === 0) return null;

  const handleLayout = (e: LayoutChangeEvent) => setWidth(e.nativeEvent.layout.width);
  // 끄는 도중 절반을 넘으면 바로 점을 옮긴다 (Flutter onPageChanged). 같은 값이면 다시 그리지 않는다
  const handleScroll = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    if (width > 0) setPage(Math.round(e.nativeEvent.contentOffset.x / width));
  };

  return (
    <View style={{ gap: spacing.sm }}>
      <View onLayout={handleLayout} style={{ aspectRatio: ASPECT_RATIO }}>
        {width > 0 && (
          <FlatList
            data={banners}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            keyExtractor={(b) => b.id ?? b.title}
            onScroll={handleScroll}
            scrollEventThrottle={16}
            getItemLayout={(_, i) => ({ length: width, offset: width * i, index: i })}
            renderItem={({ item }) => (
              <View style={{ width, aspectRatio: ASPECT_RATIO }}>
                <HomeBannerCard banner={item} />
              </View>
            )}
          />
        )}
      </View>
      {banners.length > 1 && <BannerDots count={banners.length} page={page} />}
    </View>
  );
}
