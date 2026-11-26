import { useEffect, type ComponentProps } from 'react';
import { BackHandler } from 'react-native';
import { Tabs, router, useNavigation, type Href } from 'expo-router';
import { AppBottomNav, colors } from '@/design-system';
import { askPushPermissionOnce, setPushRouterReady } from '@/features/push/pushService';
import { setNotificationSetting } from '@/features/user/hooks';

type TabBarProps = Parameters<NonNullable<ComponentProps<typeof Tabs>['tabBar']>>[0];

const HOME_INDEX = 0;

/**
 * 5개 탭 셸 (RootShell). 탭 순서 = AppBottomNav 항목 순서.
 * 시스템 뒤로가기: 탭 안 스택에 쌓인 화면이 있으면 그 화면을 닫고, 탭 첫 화면이면 홈 탭으로,
 * 홈 탭이면 앱을 닫는다(Flutter PopScope 와 같다).
 */
function TabBar({ state, emitter, navigateToTab }: TabBarProps) {
  // 루트 스택 안의 탭 셸(이 탭 내비게이터를 담은 화면)
  const navigation = useNavigation();
  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      // 탭 셸 위에 /user 같은 탭 밖 화면이 떠 있으면 그 화면의 스택이 뒤로가기를 처리한다
      if (!navigation.isFocused()) return false;
      if (state.index === HOME_INDEX) return false;      const tab = state.routes[state.index];      const nested = (tab as { state?: { index?: number; routes?: { name: string }[] } } | undefined)?.state;
      if (nested && typeof nested.index === 'number' && nested.index > 0) return false;
      // 알림으로 상세부터 열면 스택에 상세 하나뿐이다. 홈 대신 그 탭 첫 화면(목록)으로 간다
      if (tab && nested?.routes?.[0] && nested.routes[0].name !== 'index') {
        router.replace(`/${tab.name}` as Href);
        return true;
      }
      navigateToTab(state.routes[HOME_INDEX].key);
      return true;
    });
    return () => sub.remove();
  }, [state, navigation, navigateToTab]);

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
  useEffect(() => {
    // 탭이 떠야 알림으로 열 화면이 있다. 처음 한 번은 여기서 알림 권한을 묻고, 거절하면 푸시 설정도 끈다.
    setPushRouterReady(true);
    askPushPermissionOnce()
      .then((p) => {
        if (p === 'denied' || p === 'blocked') setNotificationSetting('push', false);
      })
      .catch(() => undefined);
    return () => setPushRouterReady(false);
  }, []);

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
