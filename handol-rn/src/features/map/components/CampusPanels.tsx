import { ScrollView, StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import { HPressable, HText, colors, metrics, radius, spacing } from '@/design-system';
import { showComingSoon } from '@/design-system';
import { MaterialIcon } from '@/features/empty_class/components/MaterialIcon';
import type { EmptyClass } from '@/features/empty_class/model';
import { facilities, type FacilityKey } from '../facilities';
import { MapColors } from '../theme';
import { FacilityTile, MapButton, MapSectionTitle, TileRow } from './MapCommon';

// 교내 시설(식당 · 카페 · 편의점 등)은 위치·운영 정보 API가 아직 없어
// 빈 강의실 외 시설은 누르면 '준비중' 안내만 띄운다.

function Tile({ k, onPress, enabled = true }: { k: FacilityKey; onPress?: () => void; enabled?: boolean }) {
  const f = facilities[k];
  const icon = 'icon' in f ? { asset: f.icon, material: f.material } : { material: f.material };
  return <FacilityTile label={f.label} icon={icon} enabled={enabled} onPress={onPress ?? showComingSoon} />;
}

const tiles = (keys: readonly FacilityKey[], enabled = true) => keys.map((k) => <Tile key={k} k={k} enabled={enabled} />);

/** 시트 본문 여백. 패널마다 위 · 아래 여백이 다르다 (campus_panels.dart ListView padding) */
function SheetScroll({ children, top = spacing.sm, bottom = spacing.lg }: { children: React.ReactNode; top?: number; bottom?: number }) {
  return (
    <ScrollView
      nestedScrollEnabled
      contentContainerStyle={[styles.content, { paddingTop: top, paddingBottom: bottom }]}
      showsVerticalScrollIndicator={false}
    >
      {children}
    </ScrollView>
  );
}

/** 맵 첫 화면 시트: '지금 많이 찾는 시설' + 전체보기 (2451:1122). 빈 강의실을 첫 바로가기로 둔다. */
export function CampusHomePanel({ onEmptyClass, onShowAll }: { onEmptyClass: () => void; onShowAll: () => void }) {
  return (
    <SheetScroll>
      <View style={styles.titleRow}>
        <HText variant="headline" weight="bold" tone="accent" style={{ flex: 1 }}>
          지금 많이 찾는 시설
        </HText>
        <View style={styles.clip}>
          <HPressable accessibilityRole="button" onPress={onShowAll} style={styles.showAll}>
            <HText variant="caption">전체보기</HText>
            <MaterialIcon name="chevronRight" size={18} color={colors.text} />
          </HPressable>
        </View>
      </View>
      <View style={{ height: spacing.md }} />
      <TileRow>
        <Tile k="emptyClass" onPress={onEmptyClass} />
        {tiles(['restaurant', 'cafe', 'store', 'printer', 'studyRoom'])}
      </TileRow>
    </SheetScroll>
  );
}

/** '표시할 시설 선택' 시트 (2527:2849 맵- 필터 및 레이어) */
export function FacilityFilterPanel({ onClose, onEmptyClass }: { onClose: () => void; onEmptyClass: () => void }) {
  return (
    <SheetScroll>
      <View style={styles.titleRow}>
        <HText variant="headline" weight="bold" style={{ flex: 1 }}>
          표시할 시설 선택
        </HText>
        <HPressable accessibilityRole="button" accessibilityLabel="닫기" hitSlop={8} borderless onPress={onClose} style={styles.close}>
          <MaterialIcon name="close" size={24} color={colors.text} />
        </HPressable>
      </View>
      <View style={{ height: spacing.md }} />
      <TileRow>
        <Tile k="all" onPress={onClose} />
        <Tile k="emptyClass" onPress={onEmptyClass} />
        {tiles(['restaurant', 'cafe', 'printer'])}
      </TileRow>
      <View style={{ height: 20 }} />
      <TileRow>{tiles(['studyRoom', 'store', 'vending', 'lounge', 'etc'])}</TileRow>
    </SheetScroll>
  );
}

/** '선택한 곳 다시 누르기' + X (Figma 2905:2467) */
function DeselectButton({ onPress }: { onPress: () => void }) {
  return (
    <View style={[styles.clip, { flexShrink: 1, maxWidth: '66%' }]}>
      <HPressable accessibilityRole="button" onPress={onPress} style={styles.deselect}>
        <HText variant="caption" tone="muted" style={{ textAlign: 'right', flexShrink: 1 }}>
          선택한 곳 다시 누르기
        </HText>
        <MaterialIcon name="close" size={metrics.iconSize} color={colors.inactive} />
      </HPressable>
    </View>
  );
}

/** 선택된 탭 하나짜리 탭줄: 글자 + 가는 구분선 위에 얹은 파란 막대 (Figma 2548:20515~20517) */
function InfoTab({ label }: { label: string }) {
  return (
    <View style={{ alignItems: 'center' }}>
      <HText variant="caption">{label}</HText>
      <View style={{ height: 4 }} />
      <View style={styles.tabLine}>
        <View style={styles.tabDivider} />
        <View style={styles.tabBar} />
      </View>
    </View>
  );
}

interface BuildingProps {
  building: EmptyClass;
  expanded: boolean;
  onDirections: (() => void) | null;
  onDetail: () => void;
  onEmptyClass: () => void;
  /** 건물 선택을 풀고 첫 시트로 */
  onDeselect: () => void;
}

/**
 * 지도에서 고른 건물 시트 (2548:19361), expanded 면 상세보기 (2548:20479). 건물 사진 · 학과 · 즐겨찾기 ·
 * 소개 · 층별 안내는 데이터가 없어 건물 아이콘과 빈 강의실 수로 대신하고 상세에는 준비중 문구를 둔다.
 */
export function BuildingPanel({ building, expanded, onDirections, onDetail, onEmptyClass, onDeselect }: BuildingProps) {
  const directions = <MapButton label="길찾기" icon="nearMe" onPress={onDirections ?? showComingSoon} />;
  return (
    <SheetScroll top={spacing.xs} bottom={spacing.xl}>
      <View style={styles.header}>
        <View style={styles.photo}>
          {/* Flutter: 100x80 칸에 안쪽 여백 16 을 두고 contain */}
          <Image source={building.icon} contentFit="contain" style={styles.photoImage} />
        </View>
        <View style={styles.headerText}>
          <HText variant="headline" weight="bold">
            {building.className}
          </HText>
          <View style={{ height: spacing.sm }} />
          <HText variant="caption" tone="muted">
            빈 강의실 {building.emptyCount}개
          </HText>
        </View>
        <DeselectButton onPress={onDeselect} />
      </View>
      <View style={{ height: spacing.sm }} />
      {expanded ? (
        <Detail directions={directions} onEmptyClass={onEmptyClass} />
      ) : (
        <Summary directions={directions} onDetail={onDetail} onEmptyClass={onEmptyClass} />
      )}
    </SheetScroll>
  );
}

function Detail({ directions, onEmptyClass }: { directions: React.ReactNode; onEmptyClass: () => void }) {
  return (
    <>
      {directions}
      {/* 길찾기 끝 153 → 탭 글자 199 → 구분선 223 → 주요 시설 259 */}
      <View style={{ height: 46 }} />
      <InfoTab label="시설 정보" />
      <View style={{ height: 32 }} />
      <MapSectionTitle text="주요 시설" />
      <TileRow>
        <Tile k="emptyClass" onPress={onEmptyClass} />
        {tiles(['studyRoom', 'restaurant', 'cafe', 'store'], false)}
      </TileRow>
      <View style={{ height: 20 }} />
      <MapSectionTitle text="편의 시설" />
      {/* 타일 폭 55 + 21 = 시안 간격 29 + 타일 47 (2548:20594) */}
      <View style={{ flexDirection: 'row', gap: 21 }}>{tiles(['printer', 'vending'], false)}</View>
      <View style={{ height: spacing.lg }} />
      <HText variant="caption" tone="muted">
        건물 소개 · 층별 안내는 준비중이에요
      </HText>
    </>
  );
}

function Summary({ directions, onDetail, onEmptyClass }: { directions: React.ReactNode; onDetail: () => void; onEmptyClass: () => void }) {
  return (
    <>
      <View style={{ flexDirection: 'row', gap: 29 }}>
        <View style={{ flex: 1 }}>{directions}</View>
        <View style={{ flex: 1 }}>
          <MapButton label="상세보기" primary={false} onPress={onDetail} />
        </View>
      </View>
      <View style={{ height: spacing.lg }} />
      <MapSectionTitle text="학습 공간" />
      <View style={{ flexDirection: 'row', gap: 21 }}>
        <Tile k="emptyClass" onPress={onEmptyClass} />
        {tiles(['studyRoom', 'library'])}
      </View>
      <View style={{ height: 20 }} />
      <MapSectionTitle text="생활 편의" />
      <TileRow>{tiles(['cafe', 'restaurant', 'vending', 'store', 'printer'])}</TileRow>
    </>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: metrics.pageGutter },
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  showAll: { flexDirection: 'row', alignItems: 'center' },
  /** IconButton + VisualDensity.compact = 40x40 */
  close: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  header: { flexDirection: 'row', alignItems: 'center' },
  // 손잡이 아래 사진까지 4 (Figma 2905:2464 y27)
  photo: { width: 100, height: 80, padding: spacing.md, borderRadius: radius.md, backgroundColor: MapColors.tile },
  photoImage: { flex: 1 },
  // 사진과 글 사이 5 (2905:2464 ~ 2905:2472)
  headerText: { flex: 1, minWidth: 0, marginLeft: 5 },
  deselect: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  tabLine: { height: 8, width: '100%', alignItems: 'center', justifyContent: 'center' },
  tabDivider: { position: 'absolute', left: 0, right: 0, height: 1, backgroundColor: MapColors.line },
  tabBar: { width: 50, height: 8, borderRadius: 4, backgroundColor: colors.primary },
});
