import { StyleSheet, View } from 'react-native';
import { HandolCard, HandolIconButton, HText, Icon, colors, metrics, spacing } from '@/design-system';
import { headline, isActive, type NextShuttle } from '../model';

/** 다음 버스 카드 (2156:490) */
export function NextBusCard({ next, onRefresh }: { next: NextShuttle; onRefresh: () => void }) {
  return (
    <HandolCard>
      <View style={styles.header}>
        <HText weight="bold" tone="onPrimary">
          다음 버스
        </HText>
        <View style={{ flex: 1 }} />
        <View style={styles.dot} />
        <View style={{ width: spacing.xs }} />
        <HText weight="bold" tone="onPrimary">
          실시간
        </HText>
      </View>
      <View style={styles.body}>
        <Icon name="busNext" />
        <View style={{ width: spacing.md }} />
        <View style={{ flex: 1, gap: spacing.xs }}>
          <HText variant="headline" weight="bold" tone={isActive(next) ? 'accent' : 'inactive'}>
            {headline(next)}
          </HText>
          {next.subText ? (
            <HText variant="caption" numberOfLines={2}>
              {next.subText}
            </HText>
          ) : null}
        </View>
        <View style={{ width: spacing.sm }} />
        <HandolIconButton label="새로고침" icon={<Icon name="busRefresh" />} onPress={onRefresh} />
      </View>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  header: {
    minHeight: 47,
    backgroundColor: colors.primary,
    paddingHorizontal: 15,
    flexDirection: 'row',
    alignItems: 'center',
  },
  dot: { width: 4, height: 4, borderRadius: 2, backgroundColor: colors.background },
  body: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: metrics.cardInset, paddingVertical: 12 },
});
