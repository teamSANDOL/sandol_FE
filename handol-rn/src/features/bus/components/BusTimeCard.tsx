import { Pressable, StyleSheet, View } from 'react-native';
import {
  HandolCard,
  HandolIconButton,
  HandolIconLabel,
  HandolNote,
  HText,
  Icon,
  colors,
  metrics,
  spacing,
} from '@/design-system';
import { useShuttleBoard, useShuttleDirection } from '../hooks';
import { DIRECTIONS, isSegment, reversedDirection, type StopId } from '../model';
import { refreshShuttleClock } from '../store';
import { Countdown } from './Countdown';
import { DepartureRow } from './DepartureRow';

/** 방향 띠의 짧은 정류장 이름 */
const SHORT_NAME: Record<StopId, string> = { main_campus: '학교', jeongwang: '정왕역', campus2: '제2캠퍼스' };

/**
 * 홈 셔틀버스 카드 (Figma 2153:253). 방향 띠 · 다음 출발 · 정류장 · 이후 출발 3편.
 * 계산은 셔틀 탭과 같은 useShuttleBoard 를 써서 두 화면의 표시가 항상 일치한다.
 */
export function BusTimeCard({ onPress }: { onPress?: () => void }) {
  const [direction, select] = useShuttleDirection();
  const { next, upcoming, stops, nowMinutes } = useShuttleBoard(direction);
  const { origin, destination } = DIRECTIONS[direction];
  // 머리글이 이미 다음 출발을 말하므로 같은 정시편은 빼고 그다음 편부터 보인다
  const departures = upcoming.filter((e) => isSegment(e) || e.start !== next.departureMinutes);

  return (
    <HandolCard onPress={onPress}>
      <DirectionBar
        from={SHORT_NAME[origin]}
        to={SHORT_NAME[destination]}
        onSwap={() => select(reversedDirection(direction))}
        onRefresh={refreshShuttleClock}
      />
      <View style={styles.countdown}>
        <Countdown next={next} nowMinutes={nowMinutes} />
      </View>
      <View style={styles.divider} />
      <View style={styles.body}>
        <HandolIconLabel icon={<Icon name="busStop" />} label={stops[origin]?.name ?? ''} variant="headline" weight="bold" gap={9} />
        <View style={{ height: 29 }} />
        {departures.length === 0 ? (
          <HText tone="muted">{next.subText ?? '운행 정보가 없어요'}</HText>
        ) : (
          <View style={{ gap: 12 }}>
            {departures.map((e) => (
              <DepartureRow key={`${e.type}-${e.start}`} entry={e} nowMinutes={nowMinutes} />
            ))}
          </View>
        )}
        <View style={{ height: 20 }} />
        <View style={{ alignItems: 'center' }}>
          <HandolNote text="출발 시간은 교통 상황에 따라 달라질 수 있어요." />
        </View>
      </View>
    </HandolCard>
  );
}

type BarProps = { from: string; to: string; onSwap: () => void; onRefresh: () => void };

/** primary 띠: `학교 → 정왕역` + 방향 전환 · 새로고침 버튼 */
function DirectionBar({ from, to, onSwap, onRefresh }: BarProps) {
  // 버튼을 살짝 빗나간 탭이 카드 탭(셔틀 화면 이동)으로 새지 않게 띠 전체에서 탭을 받아 버린다
  return (
    <Pressable onPress={() => undefined} style={styles.bar}>
      <View style={styles.route}>
        <HText variant="caption" tone="onPrimary">
          {from}
        </HText>
        <View style={{ transform: [{ rotate: '180deg' }] }}>
          <Icon name="arrowLeft" />
        </View>
        <HText variant="caption" tone="onPrimary">
          {to}
        </HText>
      </View>
      <View style={styles.buttons}>
        <HandolIconButton label="반대 방향" icon={<Icon name="swap" />} onPress={onSwap} />
        <HandolIconButton label="새로고침" icon={<Icon name="refresh" />} onPress={onRefresh} />
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: colors.primary,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: metrics.cardInset,
    paddingVertical: spacing.xs,
  },
  route: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  buttons: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  countdown: { paddingHorizontal: metrics.cardInset, paddingVertical: 10 },
  divider: { height: 1, backgroundColor: colors.muted },
  body: { paddingLeft: metrics.cardInset, paddingTop: 13, paddingRight: metrics.cardInset, paddingBottom: spacing.md },
});
