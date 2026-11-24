import { useState, type ReactNode } from 'react';
import { Dimensions, ScrollView, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, metrics } from '@/design-system';
import { authHorizontalPadding, authTopSpacer } from '../layout';

const BOTTOM = 32;

/** 412px 시안의 33px 여백. 좁은 화면/키보드/큰 글씨는 자연스럽게 스크롤한다 (AuthScaffold) */
export function AuthScaffold({ top, children }: { top: number; children: ReactNode }) {
  const { width } = useWindowDimensions();
  const height = Dimensions.get('screen').height;
  const insets = useSafeAreaInsets();
  const [contentHeight, setContentHeight] = useState(0);
  // 위 여백은 시안 위치(top)까지만 쓰고, 내용이 화면보다 길면 먼저 줄여(최소 16)
  // 아래 버튼이 내비게이션 바 밑으로 밀리지 않게 한다.
  const safeHeight = height - insets.top - insets.bottom;
  const spacer = // Flutter 는 SafeArea 안쪽 context 에서 상태바 높이를 읽어 0 을 빼므로 상한이 top 그대로다. 그 동작에 맞춘다.
  authTopSpacer({ top, safeHeight, contentHeight, bottom: BOTTOM });
  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.background }}
      keyboardDismissMode="on-drag"
      keyboardShouldPersistTaps="handled"
      contentContainerStyle={{
        flexGrow: 1,
        alignItems: 'center',
        paddingTop: insets.top + spacer,
        paddingBottom: insets.bottom + BOTTOM,
        paddingHorizontal: authHorizontalPadding(width, metrics.pageGutter),
      }}
    >
      <View style={{ width: '100%', maxWidth: metrics.contentWidth }} onLayout={(e) => setContentHeight(e.nativeEvent.layout.height)}>
        {children}
      </View>
    </ScrollView>
  );
}
