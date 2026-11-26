import { StyleSheet, View } from 'react-native';
import { NaverMapMarkerOverlay } from '@mj-studio/react-native-naver-map';
import { HText, colors } from '@/design-system';
import { MaterialIcon } from '@/features/empty_class/components/MaterialIcon';
import { hasLocation, type EmptyClass } from '@/features/empty_class/model';
import { BUBBLE, bubbleLayout } from '../markerSize';
import { tukIconOf, type TukPlace } from '../tukWorld';

/** 고른 마커가 다른 마커에 가려지지 않게 위로 올린다. */
const Z_SELECTED = 400000;
const Z_NORMAL = 200000;

/** 기본 확대에서 오른쪽 B동 말풍선과 겹치는 A동은 꼬리를 오른쪽에 붙여 말풍선이 왼쪽으로 펼쳐지게 한다. */
const TIP_RIGHT_BUILDING = 'A동';

/** 건물 말풍선: 건물명 + '빈 강의실 N개' 두 줄 카드와 아래 꼬리 (2451:1122 Group 90). 고르면 primary 바탕 (2548:19361) */
export function BuildingMarker({ building, selected, hidden = false, onPress }: { building: EmptyClass; selected: boolean; hidden?: boolean; onPress: () => void }) {
  if (!hasLocation(building)) return null;
  const L = bubbleLayout(building.className, building.emptyCount, building.className === TIP_RIGHT_BUILDING);
  const { margin: m, tipH, tipHalfW, padH, padV, gap } = BUBBLE;
  const fg = selected ? colors.background : colors.text;
  const bg = selected ? colors.primary : colors.background;
  return (
    <NaverMapMarkerOverlay
      latitude={building.latitude}
      longitude={building.longitude}
      width={L.width}
      height={L.height}
      anchor={L.anchor}
      globalZIndex={selected ? Z_SELECTED : Z_NORMAL}
      isHidden={hidden}
      onTap={onPress}
    >
      {/* 모양이 바뀌면 key 가 바뀌어야 네이티브가 다시 그린다 */}
      <View key={`${building.className}:${building.emptyCount}:${selected}`} collapsable={false} style={{ width: L.width, height: L.height }}>
        <View style={[styles.card, { left: m, top: m, width: L.cardW, height: L.cardH, backgroundColor: bg, paddingHorizontal: padH, paddingVertical: padV }]}>
          <HText variant="body" weight="bold" numberOfLines={1} style={{ color: fg }}>
            {building.className}
          </HText>
          <View style={{ height: gap }} />
          <HText variant="caption" numberOfLines={1} style={{ color: fg }}>
            빈 강의실 {building.emptyCount}개
          </HText>
        </View>
        <View
          style={{
            position: 'absolute',
            left: L.tipX - tipHalfW,
            top: m + L.cardH - 1,
            width: 0,
            height: 0,
            borderLeftWidth: tipHalfW,
            borderRightWidth: tipHalfW,
            borderTopWidth: tipH + 1,
            borderLeftColor: colors.transparent,
            borderRightColor: colors.transparent,
            borderTopColor: bg,
          }}
        />
      </View>
    </NaverMapMarkerOverlay>
  );
}

/** TUK 월드 업체: primary 둥근 사각 안 흰 분류 아이콘 (2544:18937, 24x24 · 고르면 32x32) */
export function PlaceMarker({ place, selected, hidden = false, onPress }: { place: TukPlace; selected: boolean; hidden?: boolean; onPress: () => void }) {
  const side = selected ? 32 : 24;
  const m = 4;
  const size = side + m * 2;
  return (
    <NaverMapMarkerOverlay
      latitude={place.latitude}
      longitude={place.longitude}
      width={size}
      height={size}
      anchor={{ x: 0.5, y: 0.5 }}
      globalZIndex={selected ? Z_SELECTED : Z_NORMAL}
      isHidden={hidden}
      onTap={onPress}
    >
      <View key={`${place.id}:${selected}`} collapsable={false} style={{ width: size, height: size, padding: m }}>
        <View style={[styles.place, { width: side, height: side, borderRadius: side / 4 }]}>
          <MaterialIcon name={tukIconOf(place)} size={side / 2} color={colors.background} />
        </View>
      </View>
    </NaverMapMarkerOverlay>
  );
}

const styles = StyleSheet.create({
  // 시안 그림자: primary 40%, 아래로 9, 블러 20 → 비트맵 여백에 맞춰 줄임
  card: { position: 'absolute', borderRadius: 12, boxShadow: '0px 4px 8px rgba(56,130,211,0.35)' },
  place: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primary, boxShadow: '0px 2px 4px rgba(56,130,211,0.3)' },
});
