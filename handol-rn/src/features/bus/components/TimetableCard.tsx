import { StyleSheet, View } from 'react-native';
import { HandolCard, HText, Icon, colors, spacing } from '@/design-system';
import { isSegment, timeLabel, type ShuttleEntry, type ShuttleTimetable } from '../model';
import { isPastEntry } from '../timetableView';

type Props = {
  title: string;
  timetable: ShuttleTimetable | null;
  nowMinutes: number;
  showPast: boolean;
};

/** 한 방향의 시간표 카드 (2905:2249 · 2905:2320). 시간 줄마다 버스 아이콘, 다음 출발 · 수시 운행 · 막차는 오른쪽 배지 */
export function TimetableCard({ title, timetable, nowMinutes, showPast }: Props) {
  const entries = timetable?.entries ?? [];
  // 다음 버스 카드와 같은 기준: 지금 이후 첫 정시편
  const next = entries.find((e) => !isSegment(e) && e.start >= nowMinutes);
  // 정시편으로 하루가 끝날 때만 막차. 뒤에 수시운행이 이어지면 막차가 아니다
  const last = entries[entries.length - 1];
  const shown = entries.filter((e) => showPast || !isPastEntry(e, nowMinutes));
  const hasUpcoming = entries.some((e) => !isPastEntry(e, nowMinutes));

  return (
    <HandolCard contentStyle={{ paddingTop: 12, paddingBottom: 36, gap: 12 }}>
      <View style={{ paddingHorizontal: 20 }}>
        <HText weight="bold" tone="accent">
          {title}
        </HText>
      </View>
      <View style={{ height: 2 }} />
      {entries.length === 0 ? (
        <CenteredNote text="오늘은 셔틀을 운행하지 않아요" />
      ) : (
        <>
          {shown.map((e) => (
            <EntryRow
              key={`${e.type}-${e.start}`}
              entry={e}
              past={isPastEntry(e, nowMinutes)}
              isNext={e === next}
              isLast={!isSegment(e) && e === last}
            />
          ))}
          {!hasUpcoming ? <CenteredNote text="오늘 남은 셔틀이 없어요" /> : null}
        </>
      )}
    </HandolCard>
  );
}

function CenteredNote({ text }: { text: string }) {
  return (
    <HText tone="inactive" style={{ textAlign: 'center' }}>
      {text}
    </HText>
  );
}

type Badge = { label: string; text: string; line: string };

function badgeOf(e: ShuttleEntry, isNext: boolean, isLast: boolean): Badge | null {
  if (e.type === 'flexible') return { label: '수시 운행', text: colors.orange, line: colors.orange };
  if (e.type === 'arrivalBoarding') return { label: '도착버스 탑승', text: colors.orange, line: colors.orange };
  if (isLast) return { label: '막차', text: colors.text, line: colors.textSecondary };
  if (isNext) return { label: '다음 출발', text: colors.primary, line: colors.border };
  return null;
}

function timeText(e: ShuttleEntry): string {
  if (!isSegment(e)) return timeLabel(e.start);
  return e.end === undefined ? `${timeLabel(e.start)} 이후` : `${timeLabel(e.start)} ~ ${timeLabel(e.end)}`;
}

type RowProps = { entry: ShuttleEntry; past: boolean; isNext: boolean; isLast: boolean };

/** `🚌 14:35            [다음 출발]` (시안: 왼쪽 17, 오른쪽 21, 줄 높이 24) */
function EntryRow({ entry, past, isNext, isLast }: RowProps) {
  const color = past ? colors.inactive : isNext ? colors.primary : colors.textSecondary;
  const badge = badgeOf(entry, isNext, isLast);
  return (
    <View style={styles.row}>
      <View style={{ flex: 1, gap: 2 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.xs }}>
          <Icon name="busRow" size={24} color={color} />
          {/* 큰 글꼴에서도 시각은 한 줄. 칸이 모자라면 줄인다 */}
          <HText weight="bold" numberOfLines={1} adjustsFontSizeToFit style={{ color, flexShrink: 1 }}>
            {timeText(entry)}
          </HText>
        </View>
        {entry.boardingNote ? (
          <HText variant="caption" tone="inactive" style={{ paddingLeft: 28 }}>
            {entry.boardingNote}
          </HText>
        ) : null}
      </View>
      {badge ? (
        <View style={[styles.badge, { borderColor: past ? colors.inactive : badge.line }]}>
          <HText variant="caption" weight="bold" style={{ color: past ? colors.inactive : badge.text }}>
            {badge.label}
          </HText>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { minHeight: 24, paddingLeft: 17, paddingRight: 21, flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  badge: {
    minWidth: 65,
    minHeight: 27,
    paddingHorizontal: spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background,
    borderWidth: 1,
    borderRadius: 30,
  },
});
