import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { HPressable, HText, colors, radius } from '@/design-system';
import { dayChips, shortWeekday, type DayChip } from '../query';
import { emptyClassTheme } from '../theme';

/** 오늘 칸을 고를 수 있는지 다시 확인하는 간격. 화면을 켜 둔 채 21:40 이 지나도 오늘 칸이 꺼진다 */
const CLOCK_CHECK_MS = 30_000;

/** 오늘부터 일주일 날짜 칸. 마지막 교시 시작(21:40)이 지나면 오늘은 고를 수 없다. */
export function DayStrip({ selected, onSelect }: { selected: number; onSelect: (daysAhead: number) => void }) {
  // Flutter 처럼 그릴 때마다 시계를 읽고, 켜 둔 동안에도 주기적으로 다시 그린다.
  const [, setTick] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), CLOCK_CHECK_MS);
    return () => clearInterval(id);
  }, []);
  const chips = dayChips();
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
