import { StyleSheet, View } from 'react-native';
import { HText, HandolCard, RemoteImage, colors, images, metrics, radius, spacing } from '@/design-system';
import { formatWon, photoKeyOf, photoUrlFor, type MenuSlot, type PhotoKey, type RestaurantMenu } from '../model';
import { HeartIcon } from './MealIcons';

const PHOTO_ASSET: Record<PhotoKey, number> = {
  gaga: images.mealGaga,
  semicon: images.mealSemicon,
  miga: images.mealMiga,
  dasol: images.mealDasol,
};

/** 식당명으로 찾은 앱 사진 에셋. 없으면 undefined */
export function photoAssetOf(name: string): number | undefined {
  const key = photoKeyOf(name);
  return key ? PHOTO_ASSET[key] : undefined;
}

/** 학식 탭 식당 카드: 위 사진 + 이름·가격 + 좋아요, 구분선, 아래 메뉴 목록 (학식-2) */
export function RestaurantCard({ menu, slot }: { menu: RestaurantMenu; slot: MenuSlot }) {
  const price = slot.price;
  return (
    <HandolCard>
      <View style={styles.head}>
        <View style={styles.photo}>
          <RemoteImage
            url={photoUrlFor(menu, slot)}
            asset={photoAssetOf(menu.restaurant.name) ?? images.mealNoPhoto}
            style={StyleSheet.absoluteFill}
          />
        </View>
        <View style={styles.titles}>
          <HText variant="headline" keepAll style={styles.keep}>
            {menu.restaurant.name}
          </HText>
          {price !== null && (
            <HText variant="body" tone="accent">
              {formatWon(price)}
            </HText>
          )}
        </View>
        {/* ponytail: 좋아요 API 가 없어 아이콘만 둔다. 서버 지원 시 숫자·토글 연결. */}
        <HeartIcon />
      </View>
      <View style={styles.divider} />
      <View style={styles.items}>
        {slot.menu.map((item, i) => (
          <HText key={`${item}-${i}`} variant="caption" keepAll style={styles.keep}>
            {item}
          </HText>
        ))}
      </View>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  head: { flexDirection: 'row', alignItems: 'flex-start', padding: metrics.cardInset },
  photo: { width: 102, height: 89, borderRadius: radius.md, overflow: 'hidden' },
  titles: { flex: 1, marginLeft: spacing.md },
  keep: {},
  divider: { height: 1, backgroundColor: colors.border },
  // Flutter Wrap(spacing 24). Android 는 글 상자 폭을 정수 픽셀로 올림해 항목마다 약 1px 넓어지므로,
  // Flutter 가 한 줄에 넣는 메뉴 수가 같도록 간격을 1dp 줄인다(눈으로는 구분되지 않는 차이).
  items: { flexDirection: 'row', flexWrap: 'wrap', columnGap: spacing.lg - 1, rowGap: spacing.md, padding: metrics.cardInset },
});
