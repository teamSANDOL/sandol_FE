import type { ComponentRef, ReactNode, Ref } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View, type ScrollViewProps } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, gradients } from '../tokens';

type Props = ScrollViewProps & {
  ref?: Ref<ComponentRef<typeof ScrollView>>;
  children: ReactNode;
  /** 당겨서 새로고침. 주면 RefreshControl 을 붙인다 */
  onRefresh?: () => void;
  isRefreshing?: boolean;
};

/**
 * 스크롤 내용 전체에 걸쳐 번지는 화면 배경 그라데이션 (HandolScrollGradient).
 * 시안 프레임이 스크롤 전체 길이라, 첫 화면은 거의 흰색이고 끝까지 내려야 보라가 짙어진다.
 * 그라데이션을 스크롤 내용 안에 깔아 내용 길이를 그대로 따른다.
 */
export function GradientScrollView({ children, contentContainerStyle, onRefresh, isRefreshing = false, ref, ...rest }: Props) {
  const g = gradients.screen;
  return (
    <ScrollView
      ref={ref}
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={[{ flexGrow: 1 }, contentContainerStyle]}
      refreshControl={
        onRefresh ? (
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={onRefresh}
            colors={[colors.primary]}
            progressBackgroundColor={colors.background}
          />
        ) : undefined
      }
      {...rest}
    >
      <View style={StyleSheet.absoluteFill} pointerEvents="none">
        <LinearGradient
          colors={g.colors as unknown as [string, string, string]}
          locations={g.locations as unknown as [number, number, number]}
          start={g.start}
          end={g.end}
          style={StyleSheet.absoluteFill}
        />
      </View>
      {children}
    </ScrollView>
  );
}

/** 스크롤하지 않는 화면 배경 그라데이션 */
export function GradientBackground({ children, style }: { children?: ReactNode; style?: ScrollViewProps['style'] }) {
  const g = gradients.screen;
  return (
    <LinearGradient
      colors={g.colors as unknown as [string, string, string]}
      locations={g.locations as unknown as [number, number, number]}
      start={g.start}
      end={g.end}
      style={[{ flex: 1 }, style as object]}
    >
      {children}
    </LinearGradient>
  );
}
