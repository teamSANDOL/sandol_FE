import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { HandolBottomSheet, colors } from '@/design-system';
import { emptyClassTheme } from '../theme';

/** 정렬 · 시간 설정 시트 (showModalBottomSheet, backgroundColor white): 36x4 손잡이 + 좌우 20 */
export function BottomSheet({ visible, onClose, children }: { visible: boolean; onClose: () => void; children: ReactNode }) {
  return (
    <HandolBottomSheet visible={visible} onClose={onClose} backgroundColor={colors.white}>
      <View style={styles.body}>
        <View style={styles.handle} />
        {children}
      </View>
    </HandolBottomSheet>
  );
}

const styles = StyleSheet.create({
  body: { paddingHorizontal: 20, paddingTop: 12, paddingBottom: 16 },
  handle: { alignSelf: 'center', width: 36, height: 4, marginBottom: 14, borderRadius: 12, backgroundColor: emptyClassTheme.sheetHandle },
});
