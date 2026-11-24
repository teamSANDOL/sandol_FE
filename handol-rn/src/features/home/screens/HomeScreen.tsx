import { useState } from 'react';
import { View } from 'react-native';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { AppTopBar, colors, GradientScrollView, HandolSection, Icon, metrics, spacing } from '@/design-system';
import { BusTimeCard } from '@/features/bus/components/BusTimeCard';
import { BuildingSortButton } from '@/features/empty_class/components/BuildingSortButton';
import { EmptyClassTimelineCard } from '@/features/empty_class/components/EmptyClassTimelineCard';
import { requestEmptyClassFocus } from '@/features/empty_class/focus';
import { OrganizationQuickCard } from '@/features/organization/components/OrganizationQuickCard';
import { HomeMealSection } from '@/features/school_meal/components/HomeMealSection';
import { homeBanners } from '../banners';
import { HomeBannerCarousel } from '../components/HomeBannerCarousel';

const EMPTY_CLASS_MAX_ITEMS = 3;

/** 홈 (Figma 홈_re 2890:2393) */
export default function HomeScreen() {
  const queryClient = useQueryClient();
  const [isRefreshing, setIsRefreshing] = useState(false);

  /** 당겨서 새로고침: 모든 섹션 쿼리를 다시 불러온다. 일부가 실패해도 인디케이터는 내려간다 */
  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await queryClient.invalidateQueries();
    } catch {
      // 각 섹션이 자기 오류·재시도를 보여 준다
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar
        title="한돌이"
        titleNode={<Icon name="logo" accessibilityLabel="한돌이" />}
        backgroundColor={colors.background}
        // 로고를 본문 여백(33)에 맞춘다. 뒤로가기 없는 바는 앞에 12를 더 둔다.
        horizontalPadding={metrics.pageGutter - 12}
      />
      <GradientScrollView
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
        contentContainerStyle={{
          paddingTop: spacing.lg,
          paddingHorizontal: metrics.pageGutter,
          paddingBottom: spacing.xl,
          gap: spacing.xl,
        }}
      >
        <HomeBannerCarousel banners={homeBanners} />
        <HandolSection title="학식">
          <HomeMealSection onPress={() => router.navigate('/meal')} />
        </HandolSection>
        <HandolSection title="셔틀버스">
          <BusTimeCard onPress={() => router.navigate('/bus')} />
        </HandolSection>
        <HandolSection title="빈 강의실" trailing={<BuildingSortButton />}>
          <EmptyClassTimelineCard
            maxItems={EMPTY_CLASS_MAX_ITEMS}
            onBuildingPress={(name) => {
              // 맵 탭이 열리면 이 건물의 빈 강의실 현황을 띄운다.
              requestEmptyClassFocus(name);
              router.navigate('/map');
            }}
          />
        </HandolSection>
        <HandolSection title="학과/부서 조회">
          <OrganizationQuickCard onOpenAll={() => router.push('/home/organization')} />
        </HandolSection>
      </GradientScrollView>
    </View>
  );
}
