import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { hapticSelection } from '@/core/haptics';
import { HText } from '@/design-system';
import { hourLabel, isToday, nearestTickIndex, ticksFor, type ClassroomQuery } from '../query';
import { classroomQueryActions, useClassroomQuery } from '../queryStore';
import { DayStrip } from './DayStrip';
import { RangeSlider, type RangeValue } from './RangeSlider';

interface Props {
  /** 드래그 중 미리보기 구간. 놓으면 null */
  onPreview?: (q: ClassroomQuery | null) => void;
}

/**
 * 조회 날짜·구간 선택기. 홈 카드와 맵 탭의 시간 설정 시트가 같이 쓴다.
 * 위에서 오늘부터 일주일 중 하루를, 아래 축에서 두 손잡이로 구간을 고른다. 값은 queryStore 하나에
 * 저장되므로 어느 화면에서 바꾸든 같은 구간을 본다.
 */
export function ClassroomTimeRangePicker({ onPreview }: Props) {
  const query = useClassroomQuery();
  // 드래그 중에는 저장소를 건드리지 않고 로컬 값만 움직인다.
  const [dragging, setDragging] = useState<RangeValue | null>(null);
  const ticks = ticksFor(query.anchorMinutes);
  const committed: RangeValue = {
    start: nearestTickIndex(ticks, query.startMinutes),
    end: nearestTickIndex(ticks, query.endMinutes),
  };

  return (
    <View>
      <DayStrip
        selected={query.daysAhead}
        onSelect={(d) => {
          hapticSelection();
          classroomQueryActions.setDay(d);
        }}
      />
      <View style={styles.gap} />
      <RangeSlider
        count={ticks.length}
        value={dragging ?? committed}
        onChange={(v) => {
          setDragging(v);
          onPreview?.({ ...query, startMinutes: ticks[v.start], endMinutes: ticks[v.end] });
        }}
        onChangeEnd={(v) => {
          setDragging(null);
          onPreview?.(null);
          classroomQueryActions.setRangeByTick(v.start, v.end);
        }}
      />
      <View style={styles.axis}>
        <HText variant="caption">{isToday(query) ? '지금' : hourLabel(ticks[0])}</HText>
        <HText variant="caption">{hourLabel(ticks[ticks.length - 1])}</HText>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  gap: { height: 12 },
  axis: { flexDirection: 'row', justifyContent: 'space-between' },
});