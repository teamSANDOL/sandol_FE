import { StyleSheet, View } from 'react-native';
import { HText, HandolCard, RemoteImage, colors, images, metrics, radius, spacing } from '@/design-system';
import { formatWon, photoKeyOf, photoUrlFor, type MenuSlot, type PhotoKey, type RestaurantMenu } from '../model';
import { mealColors } from '../theme';
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
          <HText variant="caption" weight="bold" keepAll>
            {menu.restaurant.name}
          </HText>
          {price !== null && (
            <HText variant="caption" tone="accent">
              {formatWon(price)}
            </HText>
          )}
        </View>
        {/* ponytail: 좋아요 API 가 없어 아이콘만 둔다. 서버 지원 시 숫자·토글 연결. */}
        <HeartIcon />
      </View>
      <View style={styles.divider} />
      <View style={styles.items}>
        {/* Figma 2:6443: 3열(칸 사이 4, 줄 사이 16). 한 메뉴가 두 줄이 돼도 같은 줄끼리 맞도록 줄 단위로 놓고, 칸 폭은 같게 나눈다 */}
        {rowsOf3(slot.menu).map((row, r) => (
          <View key={r} style={styles.row}>
            {[0, 1, 2].map((c) => (
              <View key={c} style={styles.item}>
                {row[c] !== undefined && (
                  <>
                    {/* 시안은 메뉴마다 목록 점(•)이 있다 (Figma 2:6447) */}
                    <HText variant="caption" style={styles.dot}>
                      •
                    </HText>
                    <HText variant="caption" keepAll style={[styles.keep, styles.flexShrink]}>
                      {row[c]}
                    </HText>
                  </>
                )}
              </View>
            ))}
          </View>
        ))}
      </View>
    </HandolCard>
  );
}

/** 메뉴를 3개씩 한 줄로 묶는다 */
function rowsOf3(menu: readonly string[]): string[][] {
  return Array.from({ length: Math.ceil(menu.length / 3) }, (_, r) => menu.slice(r * 3, r * 3 + 3));
}

const styles = StyleSheet.create({
  // Figma 2:6455 사진 90x89, 카드 안쪽 위 18 · 옆 20, 구분선까지 8
  head: { flexDirection: 'row', alignItems: 'flex-start', paddingHorizontal: metrics.cardInset, paddingTop: 18, paddingBottom: 8 },
  photo: { width: 90, height: 89, borderRadius: radius.md, overflow: 'hidden' },
  titles: { flex: 1, marginLeft: spacing.sm, gap: spacing.xs },
  keep: { lineHeight: 20 }, // 메뉴 글줄 14/20 (Figma 2:6447)
  divider: { height: 1, backgroundColor: mealColors.divider },
  // Figma 2:6443: 구분선 아래 8, 메뉴 칸 사이 4, 줄 사이 16, 아래 17. 칸 폭은 점 자리(약 20)를 포함한다.
  items: { rowGap: spacing.md, paddingHorizontal: metrics.cardInset, paddingTop: spacing.sm, paddingBottom: 17 },
  row: { flexDirection: 'row', columnGap: 4 },
  item: { flex: 1, flexDirection: 'row' },
  flexShrink: { flexShrink: 1 },
  dot: { width: 20.5, paddingLeft: 6, lineHeight: 20 },
});
