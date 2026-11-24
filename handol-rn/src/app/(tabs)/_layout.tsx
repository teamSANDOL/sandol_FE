import { useEffect, type ComponentProps } from 'react';
import { BackHandler } from 'react-native';
import { Tabs } from 'expo-router';
import { AppBottomNav, colors } from '@/design-system';

type TabBarProps = Parameters<NonNullable<ComponentProps<typeof Tabs>['tabBar']>>[0];

const HOME_INDEX = 0;

/**
 * 5개 탭 셸 (RootShell). 탭 순서 = AppBottomNav 항목 순서.
 * 시스템 뒤로가기: 탭 안 스택에 쌓인 화면이 있으면 그 화면을 닫고, 탭 첫 화면이면 홈 탭으로,
 * 홈 탭이면 앱을 닫는다(Flutter PopScope 와 같다).
 */
function TabBar({ state, emitter, navigateToTab }: TabBarProps) {
  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      if (state.index === HOME_INDEX) return false;
      const nested = (state.routes[state.index] as { state?: { index?: number } } | undefined)?.state;
      if (nested && typeof nested.index === 'number' && nested.index > 0) return false;
      navigateToTab(state.routes[HOME_INDEX].key);
      return true;
    });
    return () => sub.remove();
  }, [state, navigateToTab]);

  return (
    <AppBottomNav
      currentIndex={state.index}
      onPress={(index) => {
        const route = state.routes[index];
        // 이미 선택된 탭을 다시 누르면 스택이 첫 화면으로 돌아간다(tabPress 기본 동작).
        const event = emitter.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
        if (state.index !== index && !event.defaultPrevented) navigateToTab(route.key);
      }}
    />
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      tabBar={(props) => <TabBar {...props} />}
      backBehavior="firstRoute"
      screenOptions={{ headerShown: false, sceneStyle: { backgroundColor: colors.background } }}
    >
      <Tabs.Screen name="home" />
      <Tabs.Screen name="meal" />
      <Tabs.Screen name="bus" />
      <Tabs.Screen name="notice" />
      <Tabs.Screen name="map" />
    </Tabs>
  );
}
