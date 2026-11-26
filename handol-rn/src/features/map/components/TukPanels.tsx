import { StyleSheet, Text, View } from 'react-native';
import { ErrorRetryView, HPressable, HText, Icon, LoadingIndicator, RemoteImage, colors, metrics, radius, spacing } from '@/design-system';
import { keepAll } from '@/core/utils/keepAll';
import { MaterialIcon } from '@/features/empty_class/components/MaterialIcon';
import { TUK_CATEGORIES, tukCategoryInfo, tukIconOf, tukMatches, useTukPlaces, type TukCategory, type TukPlace } from '../tukWorld';
import { MapColors } from '../theme';
import { FacilityTile, MapButton } from './MapCommon';
import { SheetScrollView } from './SheetScrollView';

const content = { paddingHorizontal: metrics.pageGutter, paddingTop: 8.5, paddingBottom: spacing.xl } as const;

/**
 * TUK 월드 시트. 분류를 고르기 전에는 큰 타일(2544:18760), 고르면 작은 타일 줄 + 업체 목록(2544:18937).
 * 고른 분류를 다시 누르면 처음으로 돌아간다.
 */
export function TukWorldPanel({
  category,
  onCategory,
  onPlacePress,
}: {
  category: TukCategory | null;
  onCategory: (c: TukCategory | null) => void;
  onPlacePress: (p: TukPlace) => void;
}) {
  const places = useTukPlaces(true);
  return (
    <SheetScrollView nestedScrollEnabled contentContainerStyle={content} showsVerticalScrollIndicator={false}>
      {category === null ? (
        <>
          {/* 제목 윗선 36, 타일 78 (Figma 2:5122, 2:5084) */}
          <HText variant="headline" weight="bold" style={{ marginTop: 8.5 }}>
            표시할 시설 선택
          </HText>
          <View style={{ height: 20 }} />
        </>
      ) : null}
      <View style={styles.tiles}>
        {TUK_CATEGORIES.map((c) => (
          <FacilityTile
            key={c}
            label={tukCategoryInfo[c].label}
            icon={{ material: tukCategoryInfo[c].icon }}
            size={category === null ? 68 : 47}
            selected={c === category}
            labelVariant={category === null ? 'headline' : 'caption'}
            onPress={() => onCategory(c === category ? null : c)}
          />
        ))}
      </View>
      <View style={{ height: spacing.lg }} />
      {places.data ? (
        category === null ? null : <PlaceList category={category} places={places.data} onPlacePress={onPlacePress} />
      ) : places.isError ? (
        <View style={{ height: 240 }}>
          <ErrorRetryView title="TUK 월드 정보를 불러오지 못했어요" onRetry={() => void places.refetch()} />
        </View>
      ) : (
        <View style={{ padding: spacing.xl, alignItems: 'center' }}>
          <LoadingIndicator />
        </View>
      )}
    </SheetScrollView>
  );
}

function PlaceList({ category, places, onPlacePress }: { category: TukCategory; places: TukPlace[]; onPlacePress: (p: TukPlace) => void }) {
  const list = places.filter((p) => tukMatches(category, p));
  return (
    <View>
      <Text>
        <HText variant="headline">{tukCategoryInfo[category].label}  </HText>
        <HText variant="headline" tone="accent">
          {list.length}곳
        </HText>
      </Text>
      <View style={{ height: spacing.md }} />
      {list.length === 0 ? (
        <HText variant="caption" tone="muted">
          등록된 제휴 업체가 없어요
        </HText>
      ) : null}
      {list.map((p) => (
        <View key={p.id} style={{ marginBottom: spacing.md }}>
          <PlaceRow place={p} onPress={() => onPlacePress(p)} />
        </View>
      ))}
    </View>
  );
}

/** 업체 썸네일. 이미지가 없으면 분류 아이콘 타일 */
function Thumb({ place, width, height }: { place: TukPlace; width: number | string; height: number }) {
  const url = place.imageUrls[0];
  return (
    <View style={{ width: width as number, height, borderRadius: radius.md, overflow: 'hidden' }}>
      {url ? (
        <RemoteImage url={url} style={{ width: '100%', height: '100%' }} />
      ) : (
        <View style={styles.thumbFallback}>
          <MaterialIcon name={tukIconOf(place)} size={24} color={colors.primary} />
        </View>
      )}
    </View>
  );
}

/** 업체 한 줄: 사진 · 이름 · 혜택 두 줄 (2544:18937 Frame 2147235253) */
function PlaceRow({ place, onPress }: { place: TukPlace; onPress: () => void }) {
  return (
    <View style={styles.rowClip}>
      <HPressable accessibilityRole="button" accessibilityLabel={place.name} onPress={onPress} style={styles.row}>
        <Thumb place={place} width={90} height={80} />
        <View style={{ flex: 1, marginLeft: spacing.md }}>
          <HText variant="headline" weight="bold" numberOfLines={1}>
            {place.name}
          </HText>
          <View style={{ height: spacing.sm }} />
          <HText variant="caption" tone="muted" numberOfLines={2} style={{ fontSize: 12 }}>
            {keepAll(place.discountInfo ?? '')}
          </HText>
        </View>
      </HPressable>
    </View>
  );
}

/** 업체 상세 (Figma '표시한 시설 상세보기' 2541:18446). 운영시간 표 자리에 제휴 혜택, 비고 자리에 주소 */
export function TukPlaceDetail({
  place,
  onBack,
  onDirections,
  onShowOnMap,
}: {
  place: TukPlace;
  onBack: () => void;
  onDirections: () => void;
  onShowOnMap: () => void;
}) {
  return (
    <SheetScrollView nestedScrollEnabled contentContainerStyle={content} showsVerticalScrollIndicator={false}>
      <View style={styles.detailTitle}>
        <HPressable accessibilityRole="button" accessibilityLabel="뒤로" hitSlop={10} borderless onPress={onBack} style={styles.back}>
          <Icon name="backArrow" />
        </HPressable>
        <HText variant="headline" weight="bold" numberOfLines={1} style={{ flex: 1, textAlign: 'center' }}>
          {place.name}
        </HText>
        <View style={{ width: 32 }} />
      </View>
      <View style={{ height: 16.5 }} />
      {place.imageUrls.length > 0 ? (
        <>
          <Thumb place={place} width="100%" height={116} />
          <View style={{ height: spacing.sm }} />
        </>
      ) : null}
      <View style={styles.nameRow}>
        <Text style={{ flex: 1 }}>
          <HText variant="headline" weight="bold">
            {place.name}
          </HText>
          {place.category ? (
            <HText variant="caption" tone="muted">
              {'  '}
              {place.category}
            </HText>
          ) : null}
        </Text>
        <View style={{ width: 158 }}>
          <MapButton label="길찾기" icon="nearMe" bold onPress={onDirections} />
        </View>
      </View>
      <View style={{ height: spacing.md }} />
      <View style={styles.divider} />
      {/* 구분선 244 → 이용 안내 258 → 운영시간 312 → 표 346 (Figma 2:5724 ~ 2:5725) */}
      <View style={{ height: 14 }} />
      <HText variant="headline" weight="bold">
        이용 안내
      </HText>
      <View style={{ height: 32 }} />
      <HText variant="body" weight="bold">
        제휴 혜택
      </HText>
      <View style={{ height: spacing.md }} />
      <View style={styles.benefit}>
        <HText variant="body" tone="muted">
          {keepAll(place.discountInfo ?? '등록된 혜택 정보가 없어요')}
        </HText>
      </View>
      {place.address ? (
        <>
          <View style={{ height: spacing.md }} />
          <View style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
            <HText variant="body" weight="bold" style={{ width: 110 }}>
              주소
            </HText>
            <HText variant="body" tone="muted" style={{ flex: 1 }}>
              {keepAll(place.address)}
            </HText>
          </View>
        </>
      ) : null}
      <View style={{ height: spacing.lg }} />
      <MapButton label="지도에서 위치 보기" icon="place" iconSize={26} iconGap={spacing.sm} bold onPress={onShowOnMap} />
    </SheetScrollView>
  );
}

const styles = StyleSheet.create({
  tiles: { flexDirection: 'row', justifyContent: 'space-between' },
  rowClip: { borderRadius: radius.md, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center' },
  thumbFallback: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: MapColors.tile },
  // 제목 줄 높이 22 (Figma 2:5720). 뒤로 버튼은 시안에 없는 기능 진입점이라 hitSlop 으로 넓힌다.
  back: { width: 32, height: 22, justifyContent: 'center' },
  detailTitle: { flexDirection: 'row', alignItems: 'center' },
  nameRow: { flexDirection: 'row', alignItems: 'center' },
  divider: { height: 1, backgroundColor: MapColors.line },
  benefit: { paddingVertical: 24, paddingHorizontal: 20, borderRadius: radius.md, borderWidth: 1, borderColor: MapColors.line },
});
