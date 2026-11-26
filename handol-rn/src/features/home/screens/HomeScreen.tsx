import { useState } from 'react';
import { View } from 'react-native';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { AppTopBar, colors, GradientScrollView, HandolSection, Icon, metrics, spacing } from '@/design-system';
import { useRefreshUserLocation } from '@/core/location/userLocation';
import { BusTimeCard } from '@/features/bus/components/BusTimeCard';
import { refreshShuttleClock } from '@/features/bus/store';
import { BuildingSortButton } from '@/features/empty_class/components/BuildingSortButton';
import { EmptyClassTimelineCard } from '@/features/empty_class/components/EmptyClassTimelineCard';
import { requestEmptyClassFocus } from '@/features/empty_class/focus';
import { classroomQueryActions } from '@/features/empty_class/queryStore';
import { OrganizationQuickCard } from '@/features/organization/components/OrganizationQuickCard';
import { HomeMealSection } from '@/features/school_meal/components/HomeMealSection';
import { homeBanners } from '../banners';
import { HomeBannerCarousel } from '../components/HomeBannerCarousel';

const EMPTY_CLASS_MAX_ITEMS = 3;
/** 당겨서 새로고침이 다시 불러올 홈 섹션 쿼리 (Flutter home_screen _refreshAll) */
const HOME_QUERY_KEYS = [['school_meal', 'restaurants'], ['school_meal', 'meals'], ['emptyClasses'], ['organization', 'tree']];

/** 홈 (Figma 홈_re 2890:2393) */
export default function HomeScreen() {
  const queryClient = useQueryClient();
  const refreshLocation = useRefreshUserLocation();
  const [isRefreshing, setIsRefreshing] = useState(false);

  /**
   * 당겨서 새로고침: 홈 섹션 쿼리만 다시 불러온다. 일부가 실패해도 인디케이터는 내려간다.
   * 위치 갱신(최대 8초)은 기다리지 않고, 카드가 이전 정렬을 보여 준 채 뒤따라온다.
   */
  const handleRefresh = async () => {
    setIsRefreshing(true);
    classroomQueryActions.syncToNow();
    refreshShuttleClock();
    void refreshLocation();
    await Promise.allSettled(HOME_QUERY_KEYS.map((queryKey) => queryClient.invalidateQueries({ queryKey })));
    setIsRefreshing(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <AppTopBar
        title="한돌이"
        titleNode={<Icon name="logo" width={68} height={39.45} accessibilityLabel="한돌이" />}
        backgroundColor={colors.background}
        // 로고를 본문 여백(33)에 맞춘다. 뒤로가기 없는 바는 앞에 12를 더 둔다.
        horizontalPadding={metrics.pageGutter - 12}
      />
      <GradientScrollView
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
        contentContainerStyle={{
          // Figma 홈_re: 로고(68×39.45, 바 가운데) 아래 끝에서 배너까지 40.5 → 바 아래 여백 (56-39.45)/2 를 뺀 값
          paddingTop: 32.2,
          paddingHorizontal: metrics.pageGutter,
          paddingBottom: spacing.xl,
          gap: spacing.xl,
        }}
      >
        {/* 배너 아래 끝 → 학식 제목 31 (Figma). 점(8+6)이 그 사이에 들어가므로 나머지 17 만 둔다 */}
        <View style={{ marginBottom: -23 }}>
          <HomeBannerCarousel banners={homeBanners} />
        </View>
        <HandolSection title="학식">
          <HomeMealSection onPress={() => router.navigate('/meal')} />
        </HandolSection>
        <HandolSection title="셔틀버스">
          <BusTimeCard onPress={() => router.navigate('/bus')} />
        </HandolSection>
        {/* Figma: 제목→카드 간격 빈 강의실 10 · 학과/부서 9 (공통 8 에 더한다) */}
        <HandolSection title="빈 강의실" trailing={<BuildingSortButton />}>
          <View style={{ marginTop: 2 }}>
          <EmptyClassTimelineCard
            maxItems={EMPTY_CLASS_MAX_ITEMS}
            onBuildingPress={(name) => {
              // 맵 탭이 열리면 이 건물의 빈 강의실 현황을 띄운다.
              requestEmptyClassFocus(name);
              router.navigate('/map');
            }}
          />
          </View>
        </HandolSection>
        <HandolSection title="학과/부서 조회">
          <View style={{ marginTop: 1 }}>
            <OrganizationQuickCard onOpenAll={() => router.push('/home/organization')} />
          </View>
        </HandolSection>
      </GradientScrollView>
    </View>
  );
}
