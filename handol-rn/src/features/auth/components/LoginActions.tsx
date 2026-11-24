import { StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import { colors, HText, HPressable, images, radius, spacing } from '@/design-system';

type SocialProps = { source: number; label: string; onPress?: () => void };

/** 소셜 로그인 버튼 46×47 (_SocialButton) */
export function SocialButton({ source, label, onPress }: SocialProps) {
  return (
    <View style={styles.socialClip}>
      <HPressable accessibilityRole="button" accessibilityLabel={label} accessibilityState={{ disabled: !onPress }} disabled={!onPress} onPress={onPress}>
        <Image source={source} contentFit="contain" style={styles.socialImage} accessible={false} />
      </HPressable>
    </View>
  );
}

/** 카카오 · Google · Apple 한 줄 */
export function SocialRow({ isBusy, onKakao, onGoogle, onApple }: { isBusy: boolean; onKakao: () => void; onGoogle: () => void; onApple: () => void }) {
  return (
    <View style={styles.socialRow}>
      <SocialButton source={images.kakao} label="카카오로 로그인" onPress={isBusy ? undefined : onKakao} />
      <SocialButton source={images.google} label="Google로 로그인" onPress={isBusy ? undefined : onGoogle} />
      <SocialButton source={images.apple} label="Apple로 로그인" onPress={isBusy ? undefined : onApple} />
    </View>
  );
}

/** 글자만 있는 보조 버튼 (_TextAction) */
export function TextAction({ label, onPress }: { label: string; onPress?: () => void }) {
  return (
    <View style={styles.textActionClip}>
      <HPressable accessibilityRole="button" disabled={!onPress} onPress={onPress} style={styles.textAction}>
        <HText variant="caption" tone="muted" style={{ textAlign: 'center' }}>
          {label}
        </HText>
      </HPressable>
    </View>
  );
}

/** "계정이 없으시다면 회원가입하기" */
export function SignUpLink({ onPress }: { onPress?: () => void }) {
  return (
    <View style={[styles.textActionClip, { alignSelf: 'center' }]}>
      <HPressable accessibilityRole="button" disabled={!onPress} onPress={onPress} style={styles.signUp}>
        <HText variant="caption" tone="muted" style={{ textAlign: 'center' }}>
          {'계정이 없으시다면 '}
          <HText variant="caption" weight="bold" style={styles.link}>
            회원가입하기
          </HText>
        </HText>
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  socialRow: { flexDirection: 'row', justifyContent: 'center', gap: spacing.md },
  socialClip: { borderRadius: radius.md, overflow: 'hidden' },
  socialImage: { width: 46, height: 47 },
  textActionClip: { borderRadius: radius.md, overflow: 'hidden', alignSelf: 'stretch' },
  // Material TextButton 은 터치 영역을 최소 48dp 로 채운다(MaterialTapTargetSize.padded)
  textAction: { minHeight: 48, paddingHorizontal: 12, paddingVertical: 8, alignItems: 'center', justifyContent: 'center' },
  signUp: { minHeight: 48, paddingVertical: 12, paddingHorizontal: 4, alignItems: 'center', justifyContent: 'center' },
  link: { color: colors.link, textDecorationLine: 'underline' },
});
