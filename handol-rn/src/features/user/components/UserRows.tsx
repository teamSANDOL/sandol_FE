import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { Chevron, HandolCard, HandolIconLabel, HPressable, HText, Icon, colors, metrics, radius, spacing, type IconName } from '@/design-system';
import { userTheme } from '../theme';

/** 섹션 (라벨 + 카드) */
export function Section({ label, children }: { label: string; children: ReactNode }) {
  return (
    <View style={{ gap: spacing.sm }}>
      <HText variant="caption">{label}</HText>
      <HandolCard contentStyle={{ paddingHorizontal: metrics.cardInset, paddingVertical: spacing.md }}>{children}</HandolCard>
    </View>
  );
}

/** 아이콘 + 라벨 줄. 시안의 줄 간격 28을 위아래 터치 여백 12로 나눠 갖는다. */
function Row({ icon, label, danger, trailing, onPress }: { icon: IconName; label: string; danger?: boolean; trailing: ReactNode; onPress?: () => void }) {
  return (
    <View style={styles.clip}>
      <HPressable accessibilityRole="button" onPress={onPress} disabled={!onPress} style={styles.row}>
        <View style={{ flex: 1 }}>
          <HandolIconLabel
            icon={
              <View style={styles.icon}>
                <Icon name={icon} />
              </View>
            }
            label={label}
            variant="headline"
            tone={danger ? 'danger' : undefined}
          />
        </View>
        {trailing}
      </HPressable>
    </View>
  );
}

export function ToggleRow({ icon, label, value, onChange }: { icon: IconName; label: string; value: boolean; onChange: (v: boolean) => void }) {
  return <Row icon={icon} label={label} onPress={() => onChange(!value)} trailing={<Toggle value={value} />} />;
}

/** 70×32 알약 + 29×30 흰 노브 (2196:552) */
function Toggle({ value }: { value: boolean }) {
  return (
    <View
      accessibilityRole="switch"
      accessibilityState={{ checked: value }}
      style={[styles.toggle, { backgroundColor: value ? colors.primary : colors.text20, justifyContent: value ? 'flex-end' : 'flex-start' }]}
    >
      <View style={styles.knob} />
    </View>
  );
}

export function LinkRow({ icon, label, danger, trailingText, onPress }: { icon: IconName; label: string; danger?: boolean; trailingText?: string; onPress?: () => void }) {
  return (
    <Row
      icon={icon}
      label={label}
      danger={danger}
      onPress={onPress}
      trailing={
        trailingText !== undefined ? (
          <HText variant="caption" tone="muted">
            {trailingText}
          </HText>
        ) : (
          <Chevron muted />
        )
      }
    />
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12 },
  icon: { width: 26, height: 26, alignItems: 'center', justifyContent: 'center' },
  toggle: { width: 70, height: 32, borderRadius: 24, paddingHorizontal: 2, flexDirection: 'row', alignItems: 'center' },
  knob: { width: 29, height: 30, borderRadius: 15, backgroundColor: colors.white, boxShadow: userTheme.knobShadow },
});
