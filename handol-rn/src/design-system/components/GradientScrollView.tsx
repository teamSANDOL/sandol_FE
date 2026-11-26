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

/** 바닥 쪽 옅은 보라 번짐. 부모의 맨 아래에 붙는다 */
function BottomGlow() {
  const g = gradients.screen;
  return (
    <View style={[styles.glow, { height: g.height }]} pointerEvents="none">
      <LinearGradient
        colors={g.colors as unknown as [string, string]}
        locations={g.locations as unknown as [number, number]}
        start={g.start}
        end={g.end}
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
}

/**
 * 화면 배경 (HandolScrollGradient). 바탕은 background 단색, 스크롤 내용의 맨 끝에만
 * 옅은 보라 번짐이 있다 (Figma 화면 프레임의 Ellipse 12). 내용 안에 깔아 길이를 따른다.
 */
export function GradientScrollView({ children, contentContainerStyle, onRefresh, isRefreshing = false, ref, ...rest }: Props) {
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
      <BottomGlow />
      {children}
    </ScrollView>
  );
}

/** 스크롤하지 않는 화면 배경 */
export function GradientBackground({ children, style }: { children?: ReactNode; style?: ScrollViewProps['style'] }) {
  return (
    <View style={[{ flex: 1, backgroundColor: colors.background }, style as object]}>
      <BottomGlow />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  glow: { position: 'absolute', left: 0, right: 0, bottom: 0 },
});
