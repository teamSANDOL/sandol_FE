import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { HText, colors, legacyColors } from '@/design-system';
import { dayShort, timeLabel, type ClassroomQuery } from '../query';
import { useClassroomQuery } from '../queryStore';
import { emptyClassTheme } from '../theme';
import { BottomSheet } from './BottomSheet';
import { ClassroomTimeRangePicker } from './ClassroomTimeRangePicker';

/** 시간 설정 바텀시트. 맵 탭 빈 강의실 현황의 '시간 선택'에서 연다. */
export function ClassroomTimeSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const [preview, setPreview] = useState<ClassroomQuery | null>(null);
  const stored = useClassroomQuery();
  const query = preview ?? stored;
  return (
    <BottomSheet visible={visible} onClose={onClose}>
      <View style={styles.titleRow}>
        <HText legacy="title03" style={{ flex: 1, color: emptyClassTheme.black87 }}>
          시간 설정
        </HText>
        <View style={styles.badge}>
          <HText legacy="caption04" weight="bold" style={styles.badgeText}>
            {dayShort(query)} {timeLabel(query)}
          </HText>
        </View>
      </View>
      <View style={{ height: 4 }} />
      <HText legacy="caption04" style={{ color: legacyColors.textMuted }}>
        이 구간 내내 비어 있는 강의실만 보여줘요.
      </HText>
      <View style={{ height: 12 }} />
      <ClassroomTimeRangePicker onPreview={setPreview} />
      <View style={{ height: 4 }} />
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  badge: { paddingHorizontal: 9, paddingVertical: 3, borderRadius: 12, backgroundColor: legacyColors.primary },
  badgeText: { color: colors.white, fontVariant: ['tabular-nums'] },
});
