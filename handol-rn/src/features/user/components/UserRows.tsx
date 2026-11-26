import { useEffect, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, { Easing, interpolateColor, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { Chevron, HandolCard, HandolIconLabel, HPressable, HText, Icon, colors, metrics, radius, spacing, type IconName } from '@/design-system';
import { userTheme } from '../theme';

/**
 * 섹션 (라벨 + 카드). 시안 카드는 줄 높이 24(토글은 32) + 줄 간격 28 이고 위아래 18(2:6170).
 * 줄마다 위아래 14 터치 여백을 두므로 카드 안쪽 여백은 4(18 - 14)다. 토글 카드는 시안이 29 / 35 (2:6115).
 */
export function Section({ label, children, paddingTop = 4, paddingBottom = 4 }: { label: string; children: ReactNode; paddingTop?: number; paddingBottom?: number }) {
  return (
    <View style={{ gap: spacing.sm }}>
      <HText variant="caption">{label}</HText>
      <HandolCard contentStyle={{ paddingHorizontal: metrics.cardInset, paddingTop, paddingBottom }}>{children}</HandolCard>
    </View>
  );
}

/** 아이콘 + 라벨 줄. 시안의 줄 간격 28을 위아래 터치 여백 14로 나눠 갖는다. */
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

const TOGGLE_W = 70;
const TOGGLE_PAD = 2;
const KNOB_W = 29;
/** 노브가 왼쪽 끝에서 오른쪽 끝까지 움직이는 거리 */
const KNOB_TRAVEL = TOGGLE_W - TOGGLE_PAD * 2 - KNOB_W;
/** 노브 위치·바탕색 전환 (Flutter AnimatedContainer 150ms, 선형) */
const TOGGLE_TIMING = { duration: 150, easing: Easing.linear };

/** 70×32 알약 + 29×30 흰 노브 (2196:552) */
function Toggle({ value }: { value: boolean }) {
  const on = useSharedValue(value ? 1 : 0);
  useEffect(() => {
    on.value = withTiming(value ? 1 : 0, TOGGLE_TIMING);
  }, [value, on]);
  const trackStyle = useAnimatedStyle(() => ({ backgroundColor: interpolateColor(on.value, [0, 1], [colors.border, colors.primary]) }));
  const knobStyle = useAnimatedStyle(() => ({ transform: [{ translateX: on.value * KNOB_TRAVEL }] }));
  return (
    <Animated.View accessibilityRole="switch" accessibilityState={{ checked: value }} style={[styles.toggle, trackStyle]}>
      <Animated.View style={[styles.knob, knobStyle]} />
    </Animated.View>
  );
}

export function LinkRow({ icon, label, danger, trailingText, chevronColor, onPress }: { icon: IconName; label: string; danger?: boolean; trailingText?: string; chevronColor?: string; onPress?: () => void }) {
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
          <Chevron muted color={chevronColor} />
        )
      }
    />
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 14 },
  icon: { width: 26, height: 24, alignItems: 'center', justifyContent: 'center' },
  toggle: { width: TOGGLE_W, height: 32, borderRadius: 24, paddingHorizontal: TOGGLE_PAD, flexDirection: 'row', alignItems: 'center' },
  knob: { width: KNOB_W, height: 30, borderRadius: 15, backgroundColor: colors.white, boxShadow: userTheme.knobShadow },
});
