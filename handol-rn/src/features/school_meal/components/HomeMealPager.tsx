import { useEffect, useRef } from 'react';
import { Platform, StyleSheet, View, useWindowDimensions } from 'react-native';
import Animated, {
  Easing,
  cancelAnimation,
  runOnJS,
  scrollTo,
  useAnimatedReaction,
  useAnimatedRef,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
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

/** 칩 탭으로 카드를 옮길 때의 모션 (Flutter animateToPage 250ms, Curves.easeInOut) */
const SNAP_MS = 250;
/** 이보다 빠르게 놓으면(dp/ms) 절반을 못 넘어도 끈 방향의 다음 카드로 간다 */
const FLICK_VELOCITY = 0.5;
/** Android 는 snapToInterval 스냅이 이 화면에서 동작하지 않아(놓은 자리에 멈춤) 손을 떼면 직접 맞춘다 */
const JS_SNAP = Platform.OS === 'android';
const EASE_IN_OUT = Easing.bezier(0.42, 0, 0.58, 1);

/** page 실수값에서 이웃한 두 값(lo, hi)을 소수부로 보간한다. 한쪽이 없으면(0) 다른 쪽을 쓴다 */
function lerpAt(values: number[], page: number): number {
  'worklet';
  const last = values.length - 1;
  const lo = Math.min(Math.max(Math.floor(page), 0), Math.max(last, 0));
  const hi = Math.min(lo + 1, Math.max(last, 0));
  const a = values[lo] ?? 0;
  const b = values[hi] ?? 0;
  if (!a || !b) return a || b;
  return a + (b - a) * Math.min(Math.max(page - lo, 0), 1);
}

/**
 * 식당 선택 칩 줄(가로 스크롤) + 식당 메뉴 카드 가로 페이지 (Flutter HomeMealSection).
 * 카드 스크롤 위치(page 실수값)를 UI 스레드에서 매 프레임 따라 칩 줄을 밀고 카드 높이를 보간한다.
 */
export function HomeMealPager({ menus, onPress }: { menus: RestaurantMenu[]; onPress?: () => void }) {
  const { width } = useWindowDimensions();
  const pageWidth = width - 2 * metrics.pageGutter + CARD_GAP;
  const selectedId = useSelectedRestaurantId();
  const found = menus.findIndex((m) => m.restaurant.id === selectedId);
  const index = found < 0 ? 0 : found;

  const pager = useAnimatedRef<Animated.ScrollView>();
  const chips = useAnimatedRef<Animated.ScrollView>();
  const chipBox = useRef<Record<number, number>>({});
  const heightOf = useRef<Record<number, number>>({});

  const page = useSharedValue(index);
  const pageW = useSharedValue(pageWidth);
  const ids = useSharedValue<number[]>([]);
  const heights = useSharedValue<number[]>([]);
  const chipCenters = useSharedValue<number[]>([]);
  const chipContentW = useSharedValue(0);
  const viewportW = useSharedValue(width);
  /** 칩 탭 · 상세 선택으로 카드를 옮기는 중. 지나치는 중간 카드가 선택을 바꾸지 않게 막는다 */
  const animating = useSharedValue(false);
  const snapX = useSharedValue(0);
  /** 끌기 시작한 카드와 직전 스크롤 표본(속도 계산용) */
  const dragStart = useSharedValue(0);
  const lastX = useSharedValue(0);
  const lastT = useSharedValue(0);
  const velocity = useSharedValue(0);

  // 식당 목록이 바뀌면 id 순서대로 측정값을 다시 맞춘다.
  const syncMeasures = () => {
    ids.value = menus.map((m) => m.restaurant.id);
    heights.value = menus.map((m) => heightOf.current[m.restaurant.id] ?? 0);
    chipCenters.value = menus.map((m) => chipBox.current[m.restaurant.id] ?? 0);
  };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(syncMeasures, [menus]);

  // 화면 폭이 바뀌면(첫 마운트 포함) 선택 카드로 바로 옮긴다.
  useEffect(() => {
    pageW.value = pageWidth;
    viewportW.value = width;
    page.value = index;
    pager.current?.scrollTo({ x: index * pageWidth, animated: false });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pageWidth, width]);

  // 칩 탭 · 상세 페이지에서 선택이 바뀌면 카드를 250ms easeInOut 으로 옮긴다. 손가락으로 끌어 도착했으면 그대로 둔다.
  useEffect(() => {
    if (Math.round(page.value) === index) return;
    animating.value = true;
    snapX.value = page.value * pageWidth;
    snapX.value = withTiming(index * pageWidth, { duration: SNAP_MS, easing: EASE_IN_OUT }, () => {
      animating.value = false;
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index]);

  useAnimatedReaction(
    () => snapX.value,
    (x) => {
      if (animating.value) scrollTo(pager, x, 0, false);
    },
  );

  const onScroll = useAnimatedScrollHandler({
    onBeginDrag: (e) => {
      cancelAnimation(snapX);
      animating.value = false;
      dragStart.value = Math.round(e.contentOffset.x / pageW.value);
      velocity.value = 0;
    },
    onScroll: (e) => {
      const x = e.contentOffset.x;
      const t = Date.now();
      if (t > lastT.value) velocity.value = (x - lastX.value) / (t - lastT.value);
      lastX.value = x;
      lastT.value = t;
      page.value = x / pageW.value;
    },
    // 절반을 넘겼거나 빠르게 넘기면 다음 카드, 아니면 제자리 카드를 가운데로. 한 번에 한 장만 넘어간다.
    onEndDrag: (e) => {
      if (!JS_SNAP) return;
      const x = e.contentOffset.x;
      const cur = x / pageW.value;
      const start = dragStart.value;
      let target = Math.round(cur);
      const speed = Math.max(Math.abs(velocity.value), Math.abs(e.velocity?.x ?? 0));
      if (speed > FLICK_VELOCITY && target === start && cur !== start) target = start + Math.sign(cur - start);
      target = Math.min(Math.max(target, start - 1, 0), start + 1, ids.value.length - 1);
      const id = ids.value[target];
      animating.value = true;
      snapX.value = x;
      snapX.value = withTiming(target * pageW.value, { duration: SNAP_MS, easing: EASE_IN_OUT }, (done) => {
        animating.value = false;
        if (done && id !== undefined) runOnJS(selectRestaurant)(id);
      });
    },
  });

  // 끄는 도중 절반을 넘으면 바로 그 식당을 선택한다 (Flutter onPageChanged)
  useAnimatedReaction(
    () => Math.round(page.value),
    (cur, prev) => {
      if (prev === null || cur === prev || animating.value) return;
      const id = ids.value[Math.min(Math.max(cur, 0), ids.value.length - 1)];
      if (id !== undefined) runOnJS(selectRestaurant)(id);
    },
  );

  // 칩 줄을 page 에 맞춰 매 프레임 민다. 이웃한 두 칩의 가운데를 page 소수부로 보간한다.
  useAnimatedReaction(
    () => ({ center: lerpAt(chipCenters.value, page.value), max: chipContentW.value - viewportW.value }),
    ({ center, max }) => {
      if (!center) return;
      scrollTo(chips, Math.min(Math.max(center - viewportW.value / 2, 0), Math.max(max, 0)), 0, false);
    },
  );

  // 측정 전·측정값이 이상할 때는 높이를 주지 않아(자연 높이) 카드가 접히지 않는다.
  const pagerHeight = useAnimatedStyle(() => {
    const h = lerpAt(heights.value, page.value);
    return h > MIN_CARD_HEIGHT ? { height: h + 2 * SHADOW_PAD } : {};
  });

  return (
    <View>
      <Animated.ScrollView
        ref={chips}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.bleed}
        contentContainerStyle={styles.chips}
        onContentSizeChange={(w) => (chipContentW.value = w)}
      >
        {menus.map((m, i) => (
          <View
            key={m.restaurant.id}
            onLayout={(e) => {
              const { x, width: w } = e.nativeEvent.layout;
              chipBox.current[m.restaurant.id] = x + w / 2;
              syncMeasures();
            }}
          >
            <HandolChip label={m.restaurant.name} isSelected={i === index} onPress={() => selectRestaurant(m.restaurant.id)} />
          </View>
        ))}
      </Animated.ScrollView>
      <View style={{ height: spacing.sm }} />
      {/* 높이 보간은 바깥 틀에만 준다. ScrollView 자체 높이가 바뀌면 Android 가 스냅 애니메이션을 끊는다(onLayout forceFinished) */}
      <Animated.View style={[styles.pager, pagerHeight]}>
      <Animated.ScrollView
        ref={pager}
        horizontal
        showsHorizontalScrollIndicator={false}
        snapToInterval={pageWidth}
        decelerationRate="fast"
        disableIntervalMomentum
        onScroll={onScroll}
        scrollEventThrottle={16}
        style={styles.flexNone}
        contentContainerStyle={styles.pages}
      >
        {menus.map((m) => (
          <View
            key={m.restaurant.id}
            style={{ width: pageWidth, paddingHorizontal: CARD_GAP / 2 }}
            onLayout={(e) => {
              const h = e.nativeEvent.layout.height;
              if (heightOf.current[m.restaurant.id] === h) return;
              heightOf.current[m.restaurant.id] = h;
              syncMeasures();
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
      </Animated.ScrollView>
      </Animated.View>
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
  pager: { marginHorizontal: -metrics.pageGutter, marginVertical: -SHADOW_PAD, overflow: 'hidden' },
  /** 바깥 틀 높이를 따라 줄지 않게 (RN ScrollView 기본 flexShrink: 1) */
  flexNone: { flexGrow: 0, flexShrink: 0 },
  pages: { paddingHorizontal: metrics.pageGutter - CARD_GAP / 2, paddingVertical: SHADOW_PAD, alignItems: 'flex-start' },
});