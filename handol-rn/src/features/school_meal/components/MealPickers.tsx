import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { CHIP_HEIGHT, CHIP_MIN_WIDTH, HPressable, HText, colors, radius } from '@/design-system';
import { MEAL_LABEL, MEAL_TABS, type MealType, type WeekDay } from '../model';

const PILL_GAP = 4;

/** 선택 여부만 다른 둥근 칸. 선택은 primary 바탕, 아니면 테두리 (_Pill) */
function Pill({
  selected,
  onPress,
  minWidth,
  minHeight,
  children,
}: {
  selected: boolean;
  onPress: () => void;
  minWidth: number;
  minHeight: number;
  children: ReactNode;
}) {
  return (
    <View style={[styles.pillClip, { minWidth, minHeight }]}>
      <HPressable
        accessibilityRole="button"
        accessibilityState={{ selected }}
        onPress={onPress}
        style={[
          styles.pill,
          { minHeight },
          selected ? { backgroundColor: colors.primary } : { backgroundColor: colors.background, borderColor: colors.border },
        ]}
      >
        {children}
      </HPressable>
    </View>
  );
}

export function DateStrip({ days, selected, onSelect }: { days: WeekDay[]; selected: string; onSelect: (iso: string) => void }) {
  return (
    <View style={styles.row}>
      {days.map((d) => {
        const isSelected = d.iso === selected;
        return (
          <Pill key={d.iso} selected={isSelected} onPress={() => onSelect(d.iso)} minWidth={44} minHeight={50}>
            {/* 두 줄 모두 한 줄로 두고, 칸이 좁으면 글자를 줄여 맞춘다(Flutter FittedBox) */}
            {[d.weekday, `${d.month}/${d.day}`].map((line) => (
              <HText
                key={line}
                variant="caption"
                weight={isSelected ? 'bold' : undefined}
                tone={isSelected ? 'onPrimary' : 'secondary'}
                numberOfLines={1}
                adjustsFontSizeToFit
                minimumFontScale={0.7}
                style={styles.center}
              >
                {line}
              </HText>
            ))}
          </Pill>
        );
      })}
    </View>
  );
}

/** 끼니 탭. 오늘이면 지금 끼니 탭에 '• NOW' 를 붙인다. */
export function MealTabs({
  selected,
  nowType,
  onSelect,
}: {
  selected: MealType;
  nowType: MealType | null;
  onSelect: (t: MealType) => void;
}) {
  return (
    <View style={styles.row}>
      {MEAL_TABS.map((type) => (
        <Pill key={type} selected={type === selected} onPress={() => onSelect(type)} minWidth={CHIP_MIN_WIDTH} minHeight={CHIP_HEIGHT}>
          <HText variant="caption" tone={type === selected ? 'onPrimary' : undefined} numberOfLines={1} style={styles.center}>
            {type === nowType ? `${MEAL_LABEL[type]} • NOW` : MEAL_LABEL[type]}
          </HText>
        </Pill>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: PILL_GAP },
  pillClip: { flex: 1, borderRadius: radius.md, overflow: 'hidden' },
  pill: { flex: 1, borderWidth: 1, borderColor: colors.transparent, borderRadius: radius.md, paddingHorizontal: 1, paddingVertical: 2, alignItems: 'center', justifyContent: 'center' },
  center: { textAlign: 'center' },
});
