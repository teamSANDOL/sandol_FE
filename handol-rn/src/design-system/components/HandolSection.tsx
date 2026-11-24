import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { spacing } from '../tokens';
import { HText } from './HText';

type Props = {
  title: string;
  children: ReactNode;
  /** 제목 오른쪽 끝의 작은 액션 */
  trailing?: ReactNode;
  style?: StyleProp<ViewStyle>;
};

export const SECTION_TITLE_HEIGHT = 24;

/** 섹션 제목 + 본문. 홈의 학식 · 셔틀버스 … 이 같은 틀을 쓴다 (HandolSection) */
export function HandolSection({ title, children, trailing, style }: Props) {
  return (
    <View style={style}>
      <View style={styles.titleRow}>
        <HText variant="title" accessibilityRole="header" style={styles.title}>
          {title}
        </HText>
        {trailing}
      </View>
      <View style={{ height: spacing.sm }} />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  titleRow: { minHeight: SECTION_TITLE_HEIGHT, flexDirection: 'row', alignItems: 'center' },
  title: { flex: 1 },
});
