import { Stack } from 'expo-router';
import { BottomSheetHost, colors } from '@/design-system';

/** 탭 스택. 바텀시트는 이 스택(탭 씬) 위에 뜨고 탭 바는 덮지 않는다(Flutter 셸과 같다) */
export default function Layout() {
  return (
    <BottomSheetHost>
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.background } }} />
    </BottomSheetHost>
  );
}
