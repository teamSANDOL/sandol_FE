import { useCallback, useEffect, useRef, useState } from 'react';
import { Animated, BackHandler, StyleSheet, View } from 'react-native';
import { useFocusEffect } from 'expo-router';
import { NaverMapView, type NaverMapViewRef } from '@mj-studio/react-native-naver-map';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, metrics, spacing } from '@/design-system';
import { env } from '@/core/env';
import { fetchUserLocation } from '@/core/location/userLocation';
import { useEmptyClasses } from '@/features/empty_class/hooks';
import type { EmptyClass } from '@/features/empty_class/model';
import { consumeEmptyClassFocus, usePendingEmptyClassFocus } from '@/features/empty_class/focus';
import { Grip, MapCover, MapTopBar, RefreshingChip, RoundButton } from '../components/MapChrome';
import { BuildingMarker, PlaceMarker } from '../components/MapMarkers';
import { SheetContent } from '../components/SheetContent';
import { COLLAPSED_H, SNAP_FRAC, fracOf, maxFracOf } from '../panels';
import { searchPlaces } from '../search';
import { MapColors, SHEET_RADIUS } from '../theme';
import { tukMatches, useTukPlaces } from '../tukWorld';
import { useMapState } from '../useMapState';
import { useSnapSheet } from '../useSnapSheet';

/** 캠퍼스 중심 (Flutter 초기 카메라) */
const INITIAL_CAMERA = { latitude: 37.34019, longitude: 126.7336, zoom: 17 };
const NO_BUILDINGS: EmptyClass[] = [];
const CAMERA_MS = 300;
/** 검색창 + 탭 높이: 지도 위쪽 여백 */
const TOP_CONTENT_PADDING = 110;

/**
 * 맵 탭 (Figma '실제 앱 화면' > '맵' 2451:1122 외 맵-* 프레임). 지도 한 장 위에 검색창 · 교내시설/TUK 월드 탭 ·
 * 필터/내 위치 버튼을 띄우고, 아래 시트 하나가 상황에 따라 시설 바로가기 · 필터 · 건물 · 빈 강의실 현황 ·
 * TUK 월드 목록/상세로 바뀐다. 시트는 접힘 · 중간 · 거의 전체 세 높이로 멈춘다.
 */
export default function MapScreen() {
  const [bodyH, setBodyH] = useState(0);
  return (
    <View style={styles.root} onLayout={(e) => setBodyH(e.nativeEvent.layout.height)}>
      {bodyH > 0 ? <MapBody bodyH={bodyH} /> : null}
    </View>
  );
}

function MapBody({ bodyH }: { bodyH: number }) {
  const insets = useSafeAreaInsets();
  const mapRef = useRef<NaverMapViewRef>(null);
  const classes = useEmptyClasses();
  const buildings = classes.data ?? NO_BUILDINGS;
  const [search, setSearch] = useState('');
  const [searchFocused, setSearchFocused] = useState(false);

  const maxFracRef = useRef(maxFracOf('home'));
  const sheet = useSnapSheet({ bodyH, initialFrac: fracOf('home', false), maxFracRef });
  const moveCamera = useCallback((latitude: number, longitude: number) => {
    mapRef.current?.animateCameraTo({ latitude, longitude, duration: CAMERA_MS });
  }, []);
  const state = useMapState({ buildings, animateTo: sheet.animateTo, currentFrac: sheet.currentFrac, moveCamera });
  useEffect(() => {
    maxFracRef.current = maxFracOf(state.panel);
  }, [state.panel]);

  // TUK 월드는 그 탭이나 검색할 때만 불러온다. 실패하면 건물만 보여준다.
  const tuk = useTukPlaces(state.isTuk || (searchFocused && search.trim().length > 0));
  const places = tuk.data ?? [];

  useBackHandler(state.back);
  useFocusRequest(buildings, state.openEmptyClass);

  const goToMyLocation = async () => {
    const pos = await fetchUserLocation();
    if (!pos) return;
    // 권한이 확보된 시점이므로 내 위치 오버레이(파란 점)도 켠다.
    mapRef.current?.setLocationTrackingMode('NoFollow');
    moveCamera(pos.latitude, pos.longitude);
  };

  return (
    <>
      {env.naverMapEnabled ? (
        <NaverMapView
          ref={mapRef}
          style={StyleSheet.absoluteFill}
          initialCamera={INITIAL_CAMERA}
          mapType="Basic"
          isShowLocationButton={false}
          isShowZoomControls={false}
          isShowCompass={false}
          isShowScaleBar={false}
          isShowIndoorLevelPicker={false}
          mapPadding={{ top: insets.top + TOP_CONTENT_PADDING, bottom: COLLAPSED_H, left: 0, right: 0 }}
        >
          {/*
            마커는 한번 올리면 내리지 않고 isHidden 으로만 감춘다. 오버레이를 지우는 순간 네이버 지도 모듈이
            아직 붙지 않은 오버레이 목록을 인덱스로 지우려다 IndexOutOfBounds 로 앱이 죽는다(탭 전환 때 재현).
          */}
          {buildings.map((b) => (
            <BuildingMarker key={`b:${b.className}`} building={b} hidden={state.isTuk} selected={b.className === state.buildingName} onPress={() => state.openBuilding(b)} />
          ))}
          {places.map((p) => (
            <PlaceMarker
              key={`p:${p.id}`}
              place={p}
              hidden={!state.isTuk || !tukMatches(state.tukCategory ?? 'all', p)}
              selected={p.id === state.place?.id}
              onPress={() => state.openPlace(p)}
            />
          ))}
        </NaverMapView>
      ) : (
        <View style={[StyleSheet.absoluteFill, { backgroundColor: MapColors.mapFallback }]} />
      )}

      <View style={[styles.top, { top: insets.top + spacing.sm + 4 }]}>
        <MapTopBar
          isTuk={state.isTuk}
          results={searchPlaces(search, buildings, places)}
          search={search}
          onSearch={setSearch}
          focused={searchFocused}
          onFocusChange={setSearchFocused}
          onTab={(tukTab) => void state.show(tukTab ? 'tuk' : 'home')}
          onPick={(r) => {
            setSearch('');
            setSearchFocused(false);
            if (r.kind === 'building') state.openBuilding(r.building);
            else state.openPlace(r.place);
          }}
        />
      </View>

      {/*
        시트 위 12 에 붙는다. Flutter 는 시트가 한 번 움직이기 전까지 접힘 높이 기준 위치를 써서
        첫 화면에서는 버튼이 시트에 가려 윗부분만 보인다. 그대로 옮겼다.
      */}
      <Animated.View
        pointerEvents={sheet.flags.buttonsHidden ? 'none' : 'auto'}
        style={[styles.buttons, { bottom: sheet.flags.moved ? Animated.add(sheet.height, 12) : sheet.minFrac * bodyH + 12, opacity: sheet.flags.buttonsHidden ? 0 : 1 }]}
      >
        <RoundButton
          label="표시할 시설 선택"
          icon="tune"
          color={colors.muted}
          onPress={() => (state.isTuk ? state.setTukCategory(null) : void state.show('filter'))}
        />
        <RoundButton label="내 위치" icon="myLocation" onPress={() => void goToMyLocation()} />
      </Animated.View>

      <MapCover visible={sheet.flags.covered} onPress={() => void sheet.animateTo(SNAP_FRAC)} />

      <Animated.View style={[styles.sheet, { height: sheet.height }]}>
        <View style={styles.gripArea} {...sheet.gripHandlers}>
          <Grip />
        </View>
        <View style={{ flex: 1 }}>
          <SheetContent state={state} buildings={buildings} moveCamera={moveCamera} collapseSheet={() => void sheet.animateTo(sheet.minFrac)} />
        </View>
      </Animated.View>

      {classes.isPlaceholderData ? (
        <View pointerEvents="none" style={[styles.refreshing, { top: insets.top + spacing.sm + 4 }]}>
          <RefreshingChip />
        </View>
      ) : null}
    </>
  );
}

/** 시스템 뒤로가기: 첫 시트가 아니면 시트 단계를 한 칸 되돌리고, 첫 시트에서는 셸(홈 탭 복귀)에 맡긴다. */
function useBackHandler(back: () => boolean): void {
  const backRef = useRef(back);
  useEffect(() => {
    backRef.current = back;
  });
  useFocusEffect(
    useCallback(() => {
      const sub = BackHandler.addEventListener('hardwareBackPress', () => backRef.current());
      return () => sub.remove();
    }, []),
  );
}

/**
 * 홈에서 넘어온 건물 요청이 있으면 그 건물의 빈 강의실 현황을 연다. 데이터가 준비된 뒤여야 하므로
 * 요청과 데이터 어느 쪽이 늦게 와도 반응한다.
 */
function useFocusRequest(buildings: readonly EmptyClass[], open: (building: string) => Promise<void>): void {
  const pending = usePendingEmptyClassFocus();
  const openRef = useRef(open);
  useEffect(() => {
    openRef.current = open;
  });
  useEffect(() => {
    if (!pending || !buildings.some((b) => b.className === pending)) return;
    const name = consumeEmptyClassFocus();
    if (name) void openRef.current(name);
  }, [pending, buildings]);
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background },
  top: { position: 'absolute', left: metrics.pageGutter, right: metrics.pageGutter },
  buttons: { position: 'absolute', left: metrics.pageGutter, gap: spacing.sm },
  sheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: MapColors.line,
    borderTopLeftRadius: SHEET_RADIUS,
    borderTopRightRadius: SHEET_RADIUS,
    backgroundColor: colors.background,
  },
  gripArea: { alignItems: 'center', paddingTop: 7, paddingBottom: spacing.sm },
  refreshing: { position: 'absolute', left: 0, right: 0, alignItems: 'center' },
});
