import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import { colors, HText, images, metrics, spacing } from '@/design-system';

/** 한돌이 로고 (HandolBrand) */
export function HandolBrand() {
  return (
    <View style={styles.brand}>
      <Image source={images.welcomeLogo} contentFit="contain" style={styles.logo} accessibilityLabel="한돌이" />
    </View>
  );
}

/** 로고 + 가운데 정렬 제목. 강조는 children 안에서 <HText tone="accent"> 로 (AuthBrandHeading) */
export function AuthBrandHeading({ children }: { children: ReactNode }) {
  return (
    <View style={{ alignItems: 'center', gap: spacing.sm }}>
      <HandolBrand />
      <HText variant="title" style={{ textAlign: 'center' }}>
        {children}
      </HText>
    </View>
  );
}

/** 양옆 선이 있는 구분선 (AuthDivider) */
export function AuthDivider({ label }: { label: string }) {
  return (
    <View style={styles.dividerRow}>
      <View style={styles.line} />
      <HText variant="caption" tone="muted" style={styles.dividerLabel}>
        {label}
      </HText>
      <View style={styles.line} />
    </View>
  );
}

const styles = StyleSheet.create({
  brand: { alignItems: 'center' },
  logo: { width: metrics.logoSize, height: metrics.logoSize },
  dividerRow: { flexDirection: 'row', alignItems: 'center' },
  /** 시안 2:3882 는 border 색 1px 선 */
  line: { flex: 1, height: 1, backgroundColor: colors.border },
  dividerLabel: { paddingHorizontal: 20, color: colors.muted },
});
