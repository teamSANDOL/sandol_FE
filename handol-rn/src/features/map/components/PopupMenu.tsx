import { Modal, Pressable, StyleSheet, View } from 'react-native';
import { HPressable, HText, colors } from '@/design-system';

export interface PopupOption<T> {
  label: string;
  value: T;
}

/** Flutter PopupMenuButton 대응: 가운데에 뜨는 간단한 선택 목록 */
export function PopupMenu<T>({
  visible,
  options,
  onSelect,
  onClose,
}: {
  visible: boolean;
  options: readonly PopupOption<T>[];
  onSelect: (value: T) => void;
  onClose: () => void;
}) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose} statusBarTranslucent>
      <Pressable accessibilityLabel="닫기" style={styles.backdrop} onPress={onClose}>
        <View style={styles.menu}>
          {options.map((o) => (
            <HPressable
              key={o.label}
              accessibilityRole="menuitem"
              onPress={() => {
                onSelect(o.value);
                onClose();
              }}
              style={styles.item}
            >
              <HText variant="body">{o.label}</HText>
            </HPressable>
          ))}
        </View>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  menu: { minWidth: 180, maxHeight: '70%', overflow: 'hidden', borderRadius: 4, backgroundColor: colors.white, boxShadow: '0px 2px 8px rgba(0,0,0,0.3)' },
  item: { paddingHorizontal: 16, paddingVertical: 12 },
});
