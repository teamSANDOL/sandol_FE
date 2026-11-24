import { StyleSheet, View } from 'react-native';
import { HandolBottomSheet, HandolCard, HandolIconButton, HPressable, HText, Icon, colors, metrics, radius, spacing, type IconName } from '@/design-system';
import { DIRECTIONS, STOP_IDS, viaSchool, type ShuttleDirection, type ShuttleStops, type StopId } from '../model';
import type { StopEnd } from '../stopPick';

const SWAP_ROW_HEIGHT = 36.58;


type Props = {
  direction: ShuttleDirection;
  stops: ShuttleStops;
  onSwap: () => void;
  /** 정류장 선택 시트를 연다. 시트는 탭 바 위에서 끝나도록 화면 루트(StopPickerSheet)가 그린다 */
  onPick: (end: StopEnd) => void;
};



/** 출발 · 도착 카드 (2158:1281) */
export function RouteCard({ direction, stops, onSwap, onPick }: Props) {
  const { origin, destination } = DIRECTIONS[direction];
  const school = stops.main_campus?.name ?? '';

  return (
    <HandolCard>
      <HPressable accessibilityRole="button" onPress={() => onPick('origin')} style={{ paddingLeft: 18, paddingTop: 18, paddingRight: 20 }}>
        <StopRow
          icon="busStopPin"
          label="출발"
          name={stops[origin]?.name ?? ''}
          note={stops[origin]?.boardingNote}
          gap={spacing.sm}
          button="busPinButton"
          onPress={() => onPick('origin')}
        />
      </HPressable>
      <View style={styles.swapRow}>
        <View style={styles.line} />
        <HandolIconButton label="출발 · 도착 바꾸기" icon={<Icon name="busSwap" />} onPress={onSwap} />
      </View>
      <HPressable accessibilityRole="button" onPress={() => onPick('destination')} style={{ paddingLeft: 18, paddingRight: 20, paddingBottom: 24 }}>
        <StopRow
          icon="busStopFlag"
          label="도착"
          name={stops[destination]?.name ?? ''}
          note={viaSchool(direction) ? `${school} 경유` : null}
          gap={spacing.xs}
          button="busChevronButton"
          onPress={() => onPick('destination')}
        />
      </HPressable>
    </HandolCard>
  );
}

type RowProps = { icon: IconName; label: string; name: string; note?: string | null; gap: number; button: IconName; onPress: () => void };

/** `ⓟ 출발` 캡션 + 정류장 이름, 오른쪽 끝 원형 버튼 */
function StopRow({ icon, label, name, note, gap, button, onPress }: RowProps) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
      <View style={{ flex: 1 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.xs }}>
          <Icon name={icon} />
          <HText variant="caption">{label}</HText>
        </View>
        <View style={{ height: gap }} />
        <HText weight="bold" tone="secondary">
          {name}
        </HText>
        {note ? (
          <HText variant="caption" tone="inactive">
            {note}
          </HText>
        ) : null}
      </View>
      <HandolIconButton label={`${label} 정류장 선택`} icon={<Icon name={button} />} onPress={onPress} />
    </View>
  );
}

type SheetProps = {
  visible: boolean;
  title: string;
  stops: ShuttleStops;
  selected: StopId;
  onPick: (id: StopId) => void;
  onClose: () => void;
};

/** 정류장 선택 바텀시트 (_StopPickerSheet). 화면 루트에 붙여야 탭 바 위에서 끝난다 */
export function StopPickerSheet({ visible, title, stops, selected, onPick, onClose }: SheetProps) {
  return (
    <HandolBottomSheet visible={visible} onClose={onClose}>
      <View style={styles.sheetBody}>
        <HText variant="title">{title}</HText>
        <View style={{ height: spacing.sm }} />
        {STOP_IDS.map((id) => (
          <View key={id} style={styles.optionClip}>
            <HPressable accessibilityRole="button" onPress={() => onPick(id)} style={{ paddingVertical: 12 }}>
              <HText weight={id === selected ? 'bold' : undefined} tone={id === selected ? 'accent' : undefined}>
                {stops[id]?.name ?? ''}
              </HText>
            </HPressable>
          </View>
        ))}
      </View>
    </HandolBottomSheet>
  );
}

const styles = StyleSheet.create({
  swapRow: { height: SWAP_ROW_HEIGHT, alignItems: 'center', justifyContent: 'center' },
  line: { position: 'absolute', left: 0, right: 0, height: 1, backgroundColor: colors.field },
  sheetBody: { paddingTop: spacing.md, paddingBottom: spacing.md, paddingHorizontal: metrics.cardInset },
  optionClip: { borderRadius: radius.md, overflow: 'hidden' },
});
