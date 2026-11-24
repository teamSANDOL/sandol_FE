import { useEffect, useState } from 'react';
import { View } from 'react-native';
import { router } from 'expo-router';
import { AppTopBar, GradientScrollView, HText, metrics, spacing } from '@/design-system';
import { useRefreshUserLocation, useUserLocation } from '@/core/location/userLocation';
import { NextBusCard } from '../components/NextBusCard';
import { RouteCard, StopPickerSheet } from '../components/RouteCard';
import { directionAfterPick, type StopEnd } from '../stopPick';
import { DIRECTIONS } from '../model';
import { TimetableSection } from '../components/TimetableSection';
import { TransferCard } from '../components/TransferCard';
import { useShuttleBoard, useShuttleDirection } from '../hooks';
import { dayTypeOf } from '../scheduleData';
import { refreshShuttleClock } from '../store';
import { routeTitle } from '../timetableView';

const REFRESH_DELAY_MS = 300;

/**
 * 셔틀버스 탭 (Figma 2683:2828). 출발 · 도착 카드, 다음 버스 카드, 오늘 전체 시간표.
 * 다음 버스 · 지난 시각 판정은 홈 카드와 같은 시계 · 계산을 써서 두 화면이 항상 같은 출발을 가리킨다.
 */
export default function BusScreen() {
  const [direction, select] = useShuttleDirection();
  const board = useShuttleBoard(direction);
  const { stops, now, next, transfers, timetable, reversedTimetable, reversed, needsReview } = board;
  const [refreshing, setRefreshing] = useState(false);
  const [picking, setPicking] = useState<StopEnd | null>(null);
  const location = useUserLocation();
  const retryLocation = useRefreshUserLocation();

  // 사용자가 직접 연 화면이므로 위치를 스스로 얻는다. 이전에 못 얻었으면(권한 미결정 포함) 다시 시도하고,
  // 영구 거부 · 위치 꺼짐이면 묻지 않는다(useRefreshUserLocation 이 걸러 준다).
  const locationMissing = location.isFetched && location.data == null;
  useEffect(() => {
    if (locationMissing) void retryLocation();
    // 화면을 열 때 한 번만
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** 당겨서 새로고침 · 카드 버튼. 기준 시각을 갱신하면 다음 버스 · 시간표 · 마지막 업데이트가 함께 다시 계산된다 */
  const refresh = async () => {
    refreshShuttleClock();
    setRefreshing(true);
    await new Promise((r) => setTimeout(r, REFRESH_DELAY_MS));
    setRefreshing(false);
  };

  return (
    <View style={{ flex: 1 }}>
      <AppTopBar
        title="셔틀버스"
        titleNode={<HText variant="title">셔틀버스</HText>}
        onBack={() => router.navigate('/(tabs)/home')}
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding={metrics.pageGutter - 10}
      />
      <GradientScrollView
        onRefresh={refresh}
        isRefreshing={refreshing}
        contentContainerStyle={{
          paddingLeft: metrics.pageGutter,
          paddingTop: spacing.md,
          paddingRight: metrics.pageGutter,
          paddingBottom: 40,
        }}
      >
        <RouteCard direction={direction} stops={stops} onSwap={() => select(reversed)} onPick={setPicking} />
        <View style={{ height: spacing.xl }} />
        <NextBusCard next={next} onRefresh={refresh} />
        {transfers ? (
          <>
            <View style={{ height: spacing.xl }} />
            <TransferCard school={stops.main_campus?.name ?? ''} connections={transfers} />
          </>
        ) : null}
        <View style={{ height: 28 }} />
        <TimetableSection
          key={direction} // 방면이 바뀌면 지난 시간 펼침도 처음(접힘)으로
          now={now}
          dayType={dayTypeOf(now)}
          needsReview={needsReview}
          cards={[
            { title: routeTitle(direction, stops), timetable },
            { title: routeTitle(reversed, stops), timetable: reversedTimetable },
          ]}
        />
      </GradientScrollView>
      <StopPickerSheet
        visible={picking !== null}
        title={picking === 'destination' ? '도착 정류장' : '출발 정류장'}
        stops={stops}
        selected={DIRECTIONS[direction][picking === 'destination' ? 'destination' : 'origin']}
        onPick={(id) => {
          if (picking) select(directionAfterPick(direction, picking, id));
          setPicking(null);
        }}
        onClose={() => setPicking(null)}
      />
    </View>
  );
}
