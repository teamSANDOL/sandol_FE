import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { HPressable, HText, MaterialIcon, colors, radius, spacing } from '@/design-system';
import type { ShuttleDayType, ShuttleTimetable } from '../model';
import { dayLabel, footerText, isPastEntry } from '../timetableView';
import { TimetableCard } from './TimetableCard';

export type TimetableCardData = { title: string; timetable: ShuttleTimetable | null };

type Props = {
  cards: TimetableCardData[];
  /** 기준 시각 (KST 벽시계). 지난 줄 판정과 마지막 업데이트에 쓴다 */
  now: Date;
  dayType: ShuttleDayType;
  /** 서버가 최신 시간표 검증에 실패해 직전 정상본을 주는 중인지 */
  needsReview: boolean;
};

/**
 * 전체 시간표 구역 (Figma 2683:2828 안 2905:1985 · 2905:1921 · 2905:2249 · 2905:2320).
 * '전체 시간표' 제목 + 요일 배지, '지난 시간 보기' 접기 줄, 방향마다 시간표 카드, 맨 아래 안내문.
 * 다 지나간 줄은 접어 두어 지금 시각 이후부터 보인다. 지난 시간 펼침은 모든 카드가 함께 따른다.
 */
export function TimetableSection({ cards, now, dayType, needsReview }: Props) {
  const [showPast, setShowPast] = useState(false);
  const nowMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  const hasPast = cards.some((c) => (c.timetable?.entries ?? []).some((e) => isPastEntry(e, nowMinutes)));
  return (
    <View>
      <View style={styles.header}>
        <HText variant="title" style={{ flexShrink: 1 }}>
          전체 시간표
        </HText>
        <View style={styles.dayBadge}>
          <HText weight="bold" tone="accent">
            {dayLabel(dayType)}
          </HText>
        </View>
      </View>
      {hasPast ? (
        <View style={{ marginTop: spacing.sm }}>
          <PastToggle expanded={showPast} onPress={() => setShowPast((v) => !v)} />
        </View>
      ) : null}
      {cards.map((c) => (
        <View key={c.title} style={{ marginTop: 20 }}>
          <TimetableCard title={c.title} timetable={c.timetable} nowMinutes={nowMinutes} showPast={showPast} />
        </View>
      ))}
      {/* 마지막 카드 → 안내문 (Figma 2:4810 아래 1083 → 2:4809 1101) */}
      <View style={{ height: 18 }} />
      <HText variant="caption" tone="inactive" style={{ textAlign: 'center' }}>
        {footerText(now, needsReview)}
      </HText>
    </View>
  );
}

/** 접어 둔 지난 시간을 펼치고 접는 줄 (2905:1921) */
function PastToggle({ expanded, onPress }: { expanded: boolean; onPress: () => void }) {
  return (
    <View style={styles.toggleClip}>
      <HPressable accessibilityRole="button" accessibilityState={{ expanded }} onPress={onPress} style={styles.toggle}>
        <HText variant="caption" style={{ flex: 1 }}>
          {expanded ? '지난 시간 접기' : '지난 시간 보기'}
        </HText>
        <MaterialIcon name={expanded ? 'keyboardArrowUp' : 'keyboardArrowDown'} size={20} color={colors.text} />
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: spacing.sm },
  dayBadge: {
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 30,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  toggleClip: {
    borderRadius: radius.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.background,
  },
  toggle: { minHeight: 28, paddingLeft: 20, paddingRight: 10, flexDirection: 'row', alignItems: 'center' },
});
