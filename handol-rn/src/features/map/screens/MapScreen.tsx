import { useCallback, useEffect, useRef, useState } from 'react';
import { BackHandler, StyleSheet, View } from 'react-native';
import { GestureDetector } from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle } from 'react-native-reanimated';
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
import { SheetScrollProvider } from '../components/SheetScrollView';
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
const BUTTONS_ABOVE_SHEET = 20;
/** 지도 왼쪽 버튼이 사라지고 나타나는 시간 (map_screen.dart AnimatedOpacity 150ms) */
const BUTTON_FADE_MS = 150;
/** 상태바 아래 검색창까지 (Figma 2:4993 검색창 y42, 상태바 26 기준 → 16) */
const TOP_OFFSET = 16;
/** 검색창 + 탭 높이: 지도 위쪽 여백 */
const TOP_CONTENT_PADDING = 116;

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

  const sheet = useSnapSheet({ bodyH, initialFrac: fracOf('home', false), initialMaxFrac: maxFracOf('home') });
  const { height: sheetH, maxFrac } = sheet;
  const sheetStyle = useAnimatedStyle(() => ({ height: sheetH.value }));
  const buttonsStyle = useAnimatedStyle(() => ({ bottom: sheetH.value + BUTTONS_ABOVE_SHEET }));
  const moveCamera = useCallback((latitude: number, longitude: number) => {
    mapRef.current?.animateCameraTo({ latitude, longitude, duration: CAMERA_MS });
  }, []);
  const state = useMapState({ buildings, animateTo: sheet.animateTo, currentFrac: sheet.currentFrac, moveCamera });
  useEffect(() => {
    maxFrac.value = maxFracOf(state.panel);
  }, [state.panel, maxFrac]);

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

      <View style={[styles.top, { top: insets.top + TOP_OFFSET }]}>
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

      {/* 시트 윗선 위 20 (Figma 2:5048 위치 버튼 아래 636, 시트 656). 처음부터 시트 높이를 따라간다. */}
      <Animated.View
        pointerEvents={sheet.flags.buttonsHidden ? 'none' : 'auto'}
        style={[
          styles.buttons,
          buttonsStyle,
          { opacity: sheet.flags.buttonsHidden ? 0 : 1, transitionProperty: 'opacity', transitionDuration: BUTTON_FADE_MS, transitionTimingFunction: 'linear' },
        ]}
      >
        <RoundButton
          label="표시할 시설 선택"
          icon="tune"
          iconSize={26}
          onPress={() => (state.isTuk ? state.setTukCategory(null) : void state.show('filter'))}
        />
        <RoundButton label="내 위치" icon="myLocation" onPress={() => void goToMyLocation()} />
      </Animated.View>

      <MapCover visible={sheet.flags.covered} onPress={() => void sheet.animateTo(SNAP_FRAC)} />

      {/* 시트 어디서든 끌 수 있다. 목록은 시트가 최대일 때만 스크롤된다 (useSnapSheet) */}
      <GestureDetector gesture={sheet.gesture}>
        <Animated.View style={[styles.sheet, sheetStyle]}>
          <View style={styles.gripArea}>
            <Grip />
          </View>
          <View style={{ flex: 1 }}>
            <SheetScrollProvider value={sheet.scroll}>
              <SheetContent state={state} buildings={buildings} moveCamera={moveCamera} collapseSheet={() => void sheet.animateTo(sheet.minFrac)} />
            </SheetScrollProvider>
          </View>
        </Animated.View>
      </GestureDetector>

      {classes.isPlaceholderData ? (
        <View pointerEvents="none" style={[styles.refreshing, { top: insets.top + TOP_OFFSET }]}>
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
  // 두 버튼 사이 7 (Figma 2:5056 아래 582 ~ 2:5048 위 590 = 8 에서 테두리 안쪽 포함)
  buttons: { position: 'absolute', left: metrics.pageGutter, gap: 7 },
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
  // 손잡이 윗선 7.5 (Figma 2:5000 Vector 5 y11.5, 두께 8), 시트 테두리 1 포함
  gripArea: { alignItems: 'center', paddingTop: 6.5, paddingBottom: 3.5 },
  refreshing: { position: 'absolute', left: 0, right: 0, alignItems: 'center' },
});
