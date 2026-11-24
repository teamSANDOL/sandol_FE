import { useState } from 'react';
import { View } from 'react-native';
import { HandolCard, HText, HPressable, metrics, spacing } from '@/design-system';
import { timeLabel } from '../model';
import { segmentName } from '../nextShuttle';
import { isSegment } from '../model';
import type { ShuttleConnection } from '../transfer';

const rowText = (c: ShuttleConnection): string => {
  const tag = c.tight ? ' (빠듯함)' : isSegment(c.first) ? ` (${segmentName(c.first)})` : '';
  return `${timeLabel(c.departure)} 출발${tag} → 본교 ${timeLabel(c.transfer)} 환승 출발`;
};

/**
 * 직행편 말고 본교에서 갈아타는 연결. 간격이 안전 기준이라 '예상'으로 적는다.
 * "이전 버스도 보기"를 펼치면 같은 환승편에 빠듯하게 닿는 1구간 편도 보인다.
 */
export function TransferCard({ school, connections }: { school: string; connections: readonly ShuttleConnection[] }) {
  const [showTighter, setShowTighter] = useState(false);
  const hasTighter = connections.some((c) => c.tight);
  // 기본은 안전 연결만, 펼치면 빠듯한 연결까지 출발 시각순으로
  const shown = connections.filter((c) => showTighter || !c.tight);
  return (
    <HandolCard>
      <View style={{ padding: metrics.cardInset, gap: spacing.sm, alignItems: 'flex-start' }}>
        <HText weight="bold" keepAll>
          {`${school}에서 갈아타기 (예상)`}
        </HText>
        {connections.every((c) => c.tight) ? <HText tone="muted">오늘 환승 가능한 편이 없어요</HText> : null}
        {shown.map((c) => (
          <HText key={`${c.departure}-${c.transfer}`} tone={c.tight ? 'muted' : undefined} keepAll>
            {rowText(c)}
          </HText>
        ))}
        {hasTighter ? (
          <HPressable accessibilityRole="button" onPress={() => setShowTighter((v) => !v)} style={{ paddingVertical: spacing.sm }}>
            <HText tone="accent" weight="medium">
              {showTighter ? '이전 버스 숨기기' : '이전 버스도 보기'}
            </HText>
          </HPressable>
        ) : null}
        <HText variant="caption" tone="inactive" keepAll>
          환승 시간은 교통 상황에 따라 달라질 수 있어요
        </HText>
      </View>
    </HandolCard>
  );
}
