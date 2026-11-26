import { HandolIconLabel, Icon } from '@/design-system';
import { countdownText, isCounting } from '../nextShuttle';
import { headline, type NextShuttle } from '../model';
import { useSecondTick } from '../store';

/**
 * 머리글 `3분 12초 뒤 출발`. 카운트다운 구간(20분 이내)에서만 매초 흐르고 그 밖은 headline 을 그대로 쓴다.
 * 분은 공유 시계를 따르고 초만 실제 시계에서 읽어 다음 버스 카드 · 시간표와 같은 분을 가리킨다.
 */
export function Countdown({ next, nowMinutes }: { next: NextShuttle; nowMinutes: number }) {
  const counting = isCounting(next);
  const seconds = useSecondTick(counting);
  const label = counting ? countdownText(next.departureMinutes as number, nowMinutes, seconds) : headline(next);
  return <HandolIconLabel icon={<Icon name="clock" />} label={label} variant="headline" weight="bold" tone="accent" />;
}
