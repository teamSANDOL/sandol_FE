import { StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { openExternalLink } from '@/core/utils/externalLink';
import { colors, gradients, HText, HPressable, Icon, metrics, radius, RemoteImage, spacing } from '@/design-system';
import { isImageBanner, isTabRoute, type BannerLink, type HomeBanner } from '../model';
import { bannerOnGradient } from '../theme';

/** 배너 링크를 연다. 탭 루트면 탭을 바꾸고, 하위 화면이면 위에 쌓는다 */
export function openBannerLink(link: BannerLink): void {
  if (link.kind === 'external') {
    void openExternalLink(link.url);
    return;
  }
  const location = link.location as Parameters<typeof router.push>[0];
  if (isTabRoute(link.location)) router.navigate(location);
  else router.push(location);
}

function TextBanner({ banner }: { banner: HomeBanner }) {
  const g = gradients.primaryCard;
  return (
    <LinearGradient colors={g.colors as unknown as [string, string]} locations={g.locations as unknown as [number, number]} start={g.start} end={g.end} style={styles.textBanner}>
      <View style={styles.texts}>
        <HText variant="title" numberOfLines={1} style={{ color: colors.white }}>
          {banner.title}
        </HText>
        {banner.body ? (
          <HText variant="caption" numberOfLines={2} style={{ color: bannerOnGradient.body }}>
            {banner.body}
          </HText>
        ) : null}
      </View>
      {banner.icon ? (
        <View style={styles.iconCircle}>
          <Icon name={banner.icon} size={26} color={colors.white} />
        </View>
      ) : null}
    </LinearGradient>
  );
}

/** 배너 한 장. 그림 배너는 그림만, 글자 배너는 제목·설명·아이콘을 그린다 (Figma 홈_re 2901:1129) */
export function HomeBannerCard({ banner }: { banner: HomeBanner }) {
  const { link } = banner;
  const label = isImageBanner(banner) ? `광고: ${banner.title}` : banner.title;
  return (
    <View style={styles.card}>
      {isImageBanner(banner) ? (
        <RemoteImage url={banner.imageUrl} asset={banner.image} contentFit="cover" style={StyleSheet.absoluteFill} />
      ) : (
        <TextBanner banner={banner} />
      )}
      <HPressable
        accessibilityRole={link ? 'button' : undefined}
        accessibilityLabel={banner.body ? `${label}, ${banner.body}` : label}
        disabled={!link}
        onPress={link ? () => openBannerLink(link) : undefined}
        rippleColor="rgba(255,255,255,0.2)"
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  card: { flex: 1, borderRadius: radius.md, overflow: 'hidden', backgroundColor: colors.primary },
  textBanner: { flex: 1, flexDirection: 'row', alignItems: 'center', padding: metrics.cardInset, gap: spacing.md },
  texts: { flex: 1, justifyContent: 'center', gap: spacing.xs },
  iconCircle: { width: 52, height: 52, borderRadius: 26, backgroundColor: bannerOnGradient.iconCircle, alignItems: 'center', justifyContent: 'center' },
});
