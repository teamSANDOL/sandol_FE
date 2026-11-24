import { View } from 'react-native';
import { HandolIconLabel, HText, Icon, spacing } from '@/design-system';
import { isSegment, type ShuttleEntry } from '../model';
import { remainLabel, segmentName, shortClock } from '../nextShuttle';

/** 이후 출발 한 줄. 정시편은 `9:00 · N분`, 구간은 `17:00~18:00 · 수시운행` */
export function DepartureRow({ entry, nowMinutes }: { entry: ShuttleEntry; nowMinutes: number }) {
  const segment = isSegment(entry) && entry.end !== undefined;
  const time = segment ? `${shortClock(entry.start)}~${shortClock(entry.end as number)}` : shortClock(entry.start);
  const trailing = segment ? segmentName(entry) : remainLabel(entry.start - nowMinutes);
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
      <View style={{ flex: 1, alignItems: 'flex-start' }}>
        <HandolIconLabel icon={<Icon name="busDeparture" />} label={time} variant="body" gap={spacing.xs} />
      </View>
      <HText>{trailing}</HText>
    </View>
  );
}
