import { useEffect, useRef, useState, type ComponentRef } from 'react';
import { ScrollView, StyleSheet, View, useWindowDimensions, type NativeScrollEvent, type NativeSyntheticEvent } from 'react-native';
import { HText, HandolCard, HandolChip, HPressable, RemoteImage, colors, metrics, spacing } from '@/design-system';
import { selectRestaurant, useSelectedRestaurantId } from '../hooks';
import { findCurrentOrNextSlot, formatWon, photoUrlFor, type RestaurantMenu } from '../model';
import { photoAssetOf } from './RestaurantCard';

/** 이웃 카드 사이 간격 */
const CARD_GAP = 12;
const PHOTO_HEIGHT = 125;
/** 카드 그림자가 잘리지 않게 위아래로 두는 여유 */
const SHADOW_PAD = 12;
/** 이보다 작은 측정값은 레이아웃 전의 값으로 보고 무시한다 */
const MIN_CARD_HEIGHT = 40;

/** 선택된 식당의 현재(또는 다음) 끼니 메뉴 카드 (Figma 2153:237) */
function MealMenuCard({ menu }: { menu: RestaurantMenu }) {
  const slot = findCurrentOrNextSlot(menu.slots);
  const price = slot?.price ?? null;
  const photo = photoAssetOf(menu.restaurant.name);
  const photoUrl = photoUrlFor(menu, slot);
  const items = slot?.menu ?? [];
  return (
    <HandolCard color={colors.primarySoft} contentStyle={styles.cardGap}>
      {(photo !== undefined || photoUrl) && (
        <View style={{ height: PHOTO_HEIGHT }}>
          <RemoteImage url={photoUrl} asset={photo} style={StyleSheet.absoluteFill} />
        </View>
      )}
      <View style={styles.cardBody}>
        <View style={styles.titleRow}>
          <HText variant="caption" weight="bold" keepAll style={styles.name}>
            {menu.restaurant.name}
          </HText>
          {price !== null && (
            <HText variant="caption" weight="bold" tone="accent">
              {formatWon(price)}
            </HText>
          )}
        </View>
        {items.length === 0 ? (
          <HText variant="caption" tone="muted" keepAll style={styles.centerKeep}>
            오늘 메뉴가 아직 등록되지 않았어요
          </HText>
        ) : (
          items.map((item, i) => (
            <HText key={`${item}-${i}`} variant="caption" keepAll style={styles.centerKeep}>
              {item}
            </HText>
          ))
        )}
      </View>
    </HandolCard>
  );
}

/** 식당 선택 칩 줄(가로 스크롤) + 식당 메뉴 카드 가로 페이지 */
export function HomeMealPager({ menus, onPress }: { menus: RestaurantMenu[]; onPress?: () => void }) {
  const { width } = useWindowDimensions();
  const pageWidth = width - 2 * metrics.pageGutter + CARD_GAP;
  const selectedId = useSelectedRestaurantId();
  const found = menus.findIndex((m) => m.restaurant.id === selectedId);
  const index = found < 0 ? 0 : found;
  const currentId = menus[index].restaurant.id;

  const pager = useRef<ComponentRef<typeof ScrollView>>(null);
  const chips = useRef<ComponentRef<typeof ScrollView>>(null);
  const chipBox = useRef<Record<number, { x: number; w: number }>>({});
  const didMount = useRef(false);
  const [heights, setHeights] = useState<Record<number, number>>({});

  const centerChip = (id: number, animated: boolean) => {
    const box = chipBox.current[id];
    if (box) chips.current?.scrollTo({ x: box.x + box.w / 2 - width / 2, animated });
  };

  // 선택이 바뀌면(칩 탭 · 스와이프 · 상세에서 선택) 카드와 칩 줄을 그 식당에 맞춘다.
  useEffect(() => {
    pager.current?.scrollTo({ x: index * pageWidth, animated: didMount.current });
    centerChip(currentId, didMount.current);
    didMount.current = true;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, pageWidth, width]);

  const onEnd = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    const i = Math.round(e.nativeEvent.contentOffset.x / pageWidth);
    const hit = menus[Math.min(Math.max(i, 0), menus.length - 1)];
    selectRestaurant(hit.restaurant.id);
  };

  const height = heights[currentId];
  return (
    <View>
      <ScrollView ref={chips} horizontal showsHorizontalScrollIndicator={false} style={styles.bleed} contentContainerStyle={styles.chips}>
        {menus.map((m, i) => (
          <View
            key={m.restaurant.id}
            onLayout={(e) => {
              const { x, width: w } = e.nativeEvent.layout;
              chipBox.current[m.restaurant.id] = { x, w };
              if (m.restaurant.id === currentId) centerChip(currentId, false);
            }}
          >
            <HandolChip label={m.restaurant.name} isSelected={i === index} onPress={() => selectRestaurant(m.restaurant.id)} />
          </View>
        ))}
      </ScrollView>
      <View style={{ height: spacing.sm }} />
      <ScrollView
        ref={pager}
        horizontal
        showsHorizontalScrollIndicator={false}
        snapToInterval={pageWidth}
        decelerationRate="fast"
        disableIntervalMomentum
        onMomentumScrollEnd={onEnd}
        // 측정 전·측정값이 이상할 때는 높이를 주지 않아(자연 높이) 카드가 접히지 않는다.
        style={[styles.pager, height !== undefined && height > MIN_CARD_HEIGHT && { height: height + 2 * SHADOW_PAD }]}
        contentContainerStyle={styles.pages}
      >
        {menus.map((m) => (
          <View
            key={m.restaurant.id}
            style={{ width: pageWidth, paddingHorizontal: CARD_GAP / 2 }}
            onLayout={(e) => {
              const h = e.nativeEvent.layout.height;
              setHeights((prev) => (prev[m.restaurant.id] === h ? prev : { ...prev, [m.restaurant.id]: h }));
            }}
          >
            <HPressable
              accessibilityRole="button"
              onPress={() => {
                selectRestaurant(m.restaurant.id);
                onPress?.();
              }}
            >
              <MealMenuCard menu={m} />
            </HPressable>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  name: { flex: 1 },
  centerKeep: { textAlign: 'center' },
  cardGap: { gap: spacing.xs },
  cardBody: { backgroundColor: colors.background, paddingHorizontal: metrics.cardInset, paddingVertical: spacing.md, gap: spacing.sm },
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  /** 섹션 여백 밖으로 화면 끝까지 흘려 보낸다 */
  bleed: { marginHorizontal: -metrics.pageGutter, flexGrow: 0 },
  chips: { paddingHorizontal: metrics.pageGutter, gap: 12 },
  pager: { marginHorizontal: -metrics.pageGutter, marginVertical: -SHADOW_PAD, flexGrow: 0 },
  pages: { paddingHorizontal: metrics.pageGutter - CARD_GAP / 2, paddingVertical: SHADOW_PAD, alignItems: 'flex-start' },
});