import { StyleSheet, View } from 'react-native';
import { MaterialIcon } from './MaterialIcon';
import { legacyColors, radius, spacing } from '../tokens';
import { HText } from './HText';
import { HPressable } from './Pressable';
import { colors } from '../tokens';

type Props = {
  title: string;
  subtitle?: string;
  onRetry: () => void;
};

function WifiOff() {
  return <MaterialIcon name="wifiOff" size={40} color={legacyColors.textMuted} />;
}

/** 목록 · 트리를 못 불러왔을 때 공통 오류 화면 (ErrorRetryView) */
export function ErrorRetryView({ title, subtitle = '네트워크 상태를 확인한 뒤 다시 시도해 주세요', onRetry }: Props) {
  return (
    <View style={styles.wrap}>
      <WifiOff />
      <View style={{ height: 12 }} />
      <HText legacy="subtitle" weight="semibold" keepAll style={styles.center}>
        {title}
      </HText>
      <View style={{ height: spacing.xs }} />
      <HText legacy="caption04" keepAll style={[styles.center, { color: legacyColors.textSecondary, fontSize: 13 }]}>
        {subtitle}
      </HText>
      <View style={{ height: spacing.md }} />
      <View style={styles.btnClip}>
        <HPressable accessibilityRole="button" onPress={onRetry} style={styles.btn} rippleColor="rgba(255,255,255,0.2)">
          <HText variant="caption" weight="semibold" tone="onPrimary">
            다시 시도
          </HText>
        </HPressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: spacing.lg },
  center: { textAlign: 'center' },
  btnClip: { borderRadius: radius.md, overflow: 'hidden' },
  btn: { backgroundColor: colors.primary, paddingHorizontal: 24, paddingVertical: 10 },
});
