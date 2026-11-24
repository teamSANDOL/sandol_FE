import { useMemo } from 'react';
import { StyleSheet, View } from 'react-native';
import { HPressable, HText, colors, radius } from '@/design-system';
import { dayChips, shortWeekday, type DayChip } from '../query';
import { emptyClassTheme } from '../theme';

/** 오늘부터 일주일 날짜 칸. 마지막 교시 시작(21:40)이 지나면 오늘은 고를 수 없다. */
export function DayStrip({ selected, onSelect }: { selected: number; onSelect: (daysAhead: number) => void }) {
  // 화면이 다시 그려질 때마다 시계를 읽지 않도록 선택이 바뀔 때만 새로 만든다.
  const chips = useMemo(() => dayChips(), [selected]); // eslint-disable-line react-hooks/exhaustive-deps
  return (
    <View style={styles.row}>
      {chips.map((c) => (
        <Chip key={c.daysAhead} chip={c} on={c.daysAhead === selected} onSelect={onSelect} />
      ))}
    </View>
  );
}

function Chip({ chip, on, onSelect }: { chip: DayChip; on: boolean; onSelect: (d: number) => void }) {
  const color = on ? colors.white : !chip.enabled ? colors.inactive : chip.weekday === 7 ? colors.red : colors.text;
  return (
    <View style={styles.chipWrap}>
      <HPressable
        accessibilityRole="button"
        accessibilityState={{ selected: on, disabled: !chip.enabled }}
        accessibilityLabel={`${chip.month}월 ${chip.date}일 ${shortWeekday(chip.weekday)}요일`}
        disabled={!chip.enabled || on}
        onPress={() => onSelect(chip.daysAhead)}
        style={[styles.chip, { backgroundColor: on ? colors.primary : emptyClassTheme.trackSoft }]}
      >
        <HText variant="caption" style={{ color, fontSize: 11 }}>
          {chip.top}
        </HText>
        <HText variant="caption" weight="bold" style={{ color }}>
          {chip.date}
        </HText>
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: 4 },
  chipWrap: { flex: 1, borderRadius: radius.md, overflow: 'hidden' },
  chip: { alignItems: 'center', paddingVertical: 6, borderRadius: radius.md },
});
