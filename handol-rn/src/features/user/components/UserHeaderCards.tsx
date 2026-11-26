import { StyleSheet, View } from 'react-native';
import { Chevron, HandolCard, HText, Icon, colors, metrics, spacing } from '@/design-system';

/** 프로필 카드 (2158:1014) */
export function ProfileCard({ name, email }: { name: string; email: string }) {
  return (
    <HandolCard contentStyle={{ paddingHorizontal: metrics.cardInset, paddingVertical: 32 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.md }}>
        <View style={styles.avatar}>
          <Icon name="myAvatar" />
        </View>
        <View style={{ flex: 1, gap: spacing.sm }}>
          <HText variant="title" tone="accent" numberOfLines={1}>
            {name}
          </HText>
          <HText variant="body" tone="muted" numberOfLines={1}>
            {email}
          </HText>
        </View>
      </View>
    </HandolCard>
  );
}

/** 로그인하기 카드 (2195:462, 둘러보기 중) */
export function LoginCard({ onPress }: { onPress: () => void }) {
  return (
    <HandolCard onPress={onPress} accessibilityLabel="로그인하기" contentStyle={{ paddingLeft: 25, paddingRight: metrics.cardInset, paddingVertical: 36 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 26 }}>
        <Icon name="myLoginMascot" />
        <View style={{ flex: 1, gap: 6 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.xs }}>
            <HText variant="title" tone="accent">
              로그인하기
            </HText>
            <Chevron />
          </View>
          <HText variant="body" tone="muted" numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.85}>
            똑똑한 학교생활을 같이 해보아요!
          </HText>
        </View>
      </View>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  avatar: { width: 52, height: 52, borderRadius: 26, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center' },
});
