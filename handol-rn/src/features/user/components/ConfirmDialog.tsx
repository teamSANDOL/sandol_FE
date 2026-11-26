import { Modal, Pressable, StyleSheet, View } from 'react-native';
import { HPressable, HText, LoadingIndicator, MaterialIcon, colors, legacyColors, radius } from '@/design-system';
import { userTheme } from '../theme';

/** Flutter Icons.logout_rounded · Icons.error_outline_rounded · 업데이트 안내 */
const ICONS = { logout: 'logout', error: 'errorOutline', update: 'refreshRounded' } as const;
/** danger: 로그아웃·탈퇴 같은 되돌리기 어려운 확인, primary: 안내 */
const TONES = {
  danger: { color: legacyColors.danger, soft: userTheme.dangerSoft },
  primary: { color: colors.primary, soft: colors.primarySoft },
} as const;

type Props = {
  visible: boolean;
  icon: keyof typeof ICONS;
  title: string;
  message: string;
  confirmLabel: string;
  showCancel?: boolean;
  cancelLabel?: string;
  tone?: keyof typeof TONES;
  onConfirm: () => void;
  onCancel: () => void;
};

/**
 * 확인 다이얼로그 (Flutter confirm_dialog.dart). 옅은 붉은 원 아이콘 + 제목 · 설명 + [취소 · 확인].
 * 바깥(딤)을 누르면 취소로 닫힌다(showDialog 기본 barrierDismissible).
 */
export function ConfirmDialog({ visible, icon, title, message, confirmLabel, showCancel = true, cancelLabel = '취소', tone = 'danger', onConfirm, onCancel }: Props) {
  const { color, soft } = TONES[tone];
  return (
    <Modal transparent visible={visible} animationType="fade" onRequestClose={onCancel} statusBarTranslucent>
      <View style={styles.scrim}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onCancel} accessibilityLabel="닫기" />
        <View style={styles.dialog}>
          <View style={[styles.iconCircle, { backgroundColor: soft }]}>
            <MaterialIcon name={ICONS[icon]} size={28} color={color} />
          </View>
          <View style={{ height: 16 }} />
          <HText legacy="title03" style={{ fontSize: 18 }} keepAll>
            {title}
          </HText>
          <View style={{ height: 8 }} />
          <HText legacy="body" keepAll style={styles.message}>
            {message}
          </HText>
          <View style={{ height: 24 }} />
          <View style={styles.buttons}>
            {showCancel && (
              <DialogButton label={cancelLabel} background={userTheme.cancelBg} foreground={legacyColors.textSecondary} onPress={onCancel} />
            )}
            <DialogButton label={confirmLabel} background={color} foreground={legacyColors.surface} onPress={onConfirm} />
          </View>
        </View>
      </View>
    </Modal>
  );
}

function DialogButton({ label, background, foreground, onPress }: { label: string; background: string; foreground: string; onPress: () => void }) {
  return (
    <View style={[styles.btnClip, { backgroundColor: background }]}>
      <HPressable accessibilityRole="button" onPress={onPress} style={styles.btn} rippleColor="rgba(255,255,255,0.2)">
        <HText legacy="caption01" style={{ color: foreground, fontSize: 15 }}>
          {label}
        </HText>
      </HPressable>
    </View>
  );
}

/** 서버를 기다리는 동안 화면을 잠그는 로딩 (Flutter runBlocking) */
export function BlockingOverlay({ visible }: { visible: boolean }) {
  return (
    <Modal transparent visible={visible} animationType="none" statusBarTranslucent onRequestClose={() => undefined}>
      <View style={[styles.scrim, { padding: 0 }]}>
        <LoadingIndicator />
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: { flex: 1, backgroundColor: userTheme.scrim, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 40 },
  dialog: {
    alignSelf: 'stretch',
    alignItems: 'center',
    backgroundColor: legacyColors.surface,
    borderRadius: radius.md,
    paddingHorizontal: 24,
    paddingTop: 28,
    paddingBottom: 20,
  },
  iconCircle: { width: 56, height: 56, borderRadius: 28, alignItems: 'center', justifyContent: 'center' },
  message: { textAlign: 'center', lineHeight: 21, color: legacyColors.textSecondary },
  buttons: { flexDirection: 'row', gap: 10, alignSelf: 'stretch' },
  btnClip: { flex: 1, borderRadius: radius.md, overflow: 'hidden' },
  btn: { minHeight: 48, alignItems: 'center', justifyContent: 'center' },
});
