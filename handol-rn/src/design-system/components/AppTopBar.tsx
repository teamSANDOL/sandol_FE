import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { colors, metrics } from '../tokens';
import { HText } from './HText';
import { Icon } from './Icon';
import { HPressable } from './Pressable';

type Props = {
  title: string;
  /** 제목 자리에 텍스트 대신 그릴 요소 (홈의 로고) */
  titleNode?: ReactNode;
  /** null 이면 뒤로가기 버튼을 그리지 않는다 */
  onBack?: () => void;
  /** 유저 아이콘 탭 동작. 없으면 /user 로 이동 */
  onUser?: () => void;
  showUser?: boolean;
  /** 유저 아이콘 자리에 두는 다른 액션 (마이페이지 로그아웃 등) */
  trailing?: ReactNode;
  /** 바 아래에 덧붙일 요소 (공지 탭의 탭바) */
  bottom?: ReactNode;
  backgroundColor?: string;
  /** 바 좌우 바깥 여백 */
  horizontalPadding?: number;
  /** 상태바 높이만큼 위 여백을 둘지. 셸 밖 화면도 기본 true */
  withSafeArea?: boolean;
  style?: StyleProp<ViewStyle>;
};

/** 상단 바 전용 아이콘 버튼. 터치 영역 44x44 */
export function BarIconButton({ children, label, onPress }: { children: ReactNode; label: string; onPress: () => void }) {
  return (
    <View style={styles.iconClip}>
      <HPressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={styles.icon} borderless>
        {children}
      </HPressable>
    </View>
  );
}

/** 앱 전체 공통 상단 바 (AppTopBar). 높이 56 */
export function AppTopBar({
  title,
  titleNode,
  onBack,
  onUser,
  showUser = true,
  trailing,
  bottom,
  backgroundColor = colors.background,
  horizontalPadding = 8,
  withSafeArea = true,
  style,
}: Props) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[{ backgroundColor, paddingTop: withSafeArea ? insets.top : 0 }, style]}>
      <View style={[styles.bar, { paddingHorizontal: horizontalPadding }]}>
        {onBack ? (
          <BarIconButton label="뒤로" onPress={onBack}>
            <Icon name="backArrow" />
          </BarIconButton>
        ) : (
          <View style={{ width: 12 }} />
        )}
        <View style={styles.title}>
          {titleNode ?? (
            <HText legacy="title02" numberOfLines={1}>
              {title}
            </HText>
          )}
        </View>
        {showUser && (
          <BarIconButton label="내 정보" onPress={onUser ?? (() => router.push('/user'))}>
            <Icon name="user" />
          </BarIconButton>
        )}
        {trailing}
      </View>
      {bottom}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: { height: metrics.topBarHeight, flexDirection: 'row', alignItems: 'center' },
  title: { flex: 1, alignItems: 'flex-start', justifyContent: 'center' },
  iconClip: { borderRadius: 22, overflow: 'hidden' },
  icon: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
});
