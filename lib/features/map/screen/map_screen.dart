import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/map/component/campus_panels.dart';
import 'package:handori/features/map/component/empty_class_panel.dart';
import 'package:handori/features/map/component/map_common.dart';
import 'package:handori/features/map/component/map_markers.dart';
import 'package:handori/features/map/component/tuk_world_panel.dart';
import 'package:handori/features/map/data/tuk_place.dart';
import 'package:handori/features/map/presentation/provider/tuk_world_provider.dart';

/// 시트에 무엇을 보여줄지. TUK 월드 시트면 상단 탭도 'TUK 월드'다.
enum _Panel {
  home,
  filter,
  building,
  buildingDetail,
  emptyClass,
  tuk,
  tukDetail;

  bool get isTuk => this == tuk || this == tukDetail;
}

/// 맵 탭 (Figma '실제 앱 화면' > '맵' 2451:1122 외 맵-* 프레임).
///
/// 지도 한 장 위에 검색창 · 교내시설/TUK 월드 탭 · 필터/내 위치 버튼을 띄우고,
/// 아래 시트 하나가 상황에 따라 시설 바로가기 · 필터 · 건물 · 빈 강의실 현황 ·
/// TUK 월드 목록/상세로 바뀐다. 시트는 접힘 · 중간 · 거의 전체 세 높이로 멈추고,
/// 거의 전체일 때는 지도를 어둡게 덮어 '지도' 라벨을 보여준다(누르면 내려감).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, @visibleForTesting this.mapOverride});

  /// 테스트에서 네이버 지도(플랫폼 뷰) 대신 그릴 위젯. 지도 컨트롤러가 없으면
  /// 마커·카메라 동작은 건너뛴다.
  final Widget? mapOverride;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  /// 시트 높이 3단 (본문 높이 비율). 접힘만 픽셀 기준이다.
  static const _collapsedH = 120.0;
  static const _snapFrac = 0.42;
  static const _maxFrac = 0.9;

  /// 이보다 높이 올라가면 지도를 덮고 '지도' 라벨을 보여준다.
  static const _coverFrac = 0.7;

  _Panel _panel = _Panel.home;
  String? _buildingName;
  TukCategory? _tukCategory;
  TukPlace? _place;

  /// 빈 강의실 시트가 다 올라온 뒤 스크롤할 건물
  String? _focusBuilding;

  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  final _sheetCtrl = DraggableScrollableController();
  NaverMapController? _mapController;
  NCameraPosition _initialCamera = const NCameraPosition(
    target: NLatLng(37.34019, 126.7336),
    zoom: 17.0,
  );

  /// 기본 확대에서 오른쪽 B동 말풍선과 겹치는 A동은 꼬리를 오른쪽에 붙여
  /// 말풍선이 왼쪽으로 펼쳐지게 한다.
  static const _tipRightBuilding = 'A동';

  /// 마커 아이콘 캐시. 항목은 플러그인이 만든 임시 파일 경로와 앵커·크기뿐이라
  /// 메모리는 수십 바이트 단위다. 화면과 함께 사라지므로 상한을 두지 않는다.
  final Map<String, MarkerIcon> _iconCache = {};
  int _markerGen = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // ── 시트 ──────────────────────────────────────────────────────────────

  static double _fracOf(_Panel p, TukCategory? category) => switch (p) {
    _Panel.home => 0.3,
    _Panel.filter => _snapFrac,
    _Panel.building => 0.55,
    _Panel.tuk => category == null ? 0.38 : 0.55,
    _Panel.buildingDetail || _Panel.emptyClass || _Panel.tukDetail => _maxFrac,
  };

  Future<void> _animateSheet(double frac) async {
    if (!_sheetCtrl.isAttached) return;
    await _sheetCtrl.animateTo(
      frac,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// 시트 내용을 바꾸고 그 내용에 맞는 높이로 올린다.
  Future<void> _show(_Panel p) async {
    final tabChanged = p.isTuk != _panel.isTuk;
    setState(() {
      _panel = p;
      _focusBuilding = null;
    });
    if (tabChanged) _refreshMarkers();
    // 시트 안 스크롤러블이 새 내용으로 바뀌는 프레임에 애니메이션을 시작하면
    // 옛 스크롤 위치가 떨어지며 멈추므로, 바뀐 뒤에 올린다.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _animateSheet(_fracOf(p, _tukCategory));
  }

  /// 시스템 뒤로가기 · 시트의 뒤로 버튼. 첫 시트에서는 [PopScope]가 막지 않아
  /// 셸이 홈 탭으로 돌린다.
  void _back() {
    switch (_panel) {
      case _Panel.home:
        return;
      case _Panel.filter || _Panel.building:
        _selectBuilding(null);
        _show(_Panel.home);
      case _Panel.buildingDetail:
        _show(_Panel.building);
      case _Panel.emptyClass:
        _show(_buildingName == null ? _Panel.home : _Panel.building);
      case _Panel.tuk:
        if (_tukCategory != null) {
          _setTukCategory(null);
        } else {
          _show(_Panel.home);
        }
      case _Panel.tukDetail:
        _selectPlace(null);
        _show(_Panel.tuk);
    }
  }

  double _minFrac(double bodyH) =>
      (_collapsedH / bodyH).clamp(0.08, 0.35).toDouble();

  // 손잡이는 스크롤러블 밖에 있으므로 시트 컨트롤러를 직접 구동한다.
  // 리스트가 어디까지 스크롤돼 있든 손잡이 드래그는 항상 시트를 움직인다.
  void _onGripDragUpdate(DragUpdateDetails d, double minFrac, double bodyH) {
    if (!_sheetCtrl.isAttached) return;
    _sheetCtrl.jumpTo(
      (_sheetCtrl.size - d.delta.dy / bodyH).clamp(minFrac, _maxFrac),
    );
  }

  void _onGripDragEnd(DragEndDetails d, double minFrac, double bodyH) {
    if (!_sheetCtrl.isAttached) return;
    final v = -d.velocity.pixelsPerSecond.dy / bodyH; // 위로 드래그가 양수
    final cur = _sheetCtrl.size;
    final stops = [minFrac, _snapFrac, _maxFrac];
    final double target;
    if (v.abs() > 0.9) {
      // 플링: 진행 방향의 다음 정지점으로
      target =
          v > 0
              ? stops.firstWhere((s) => s > cur + 0.01, orElse: () => _maxFrac)
              : stops.lastWhere((s) => s < cur - 0.01, orElse: () => minFrac);
    } else {
      // 가장 가까운 정지점으로
      target = stops.reduce(
        (a, b) => (a - cur).abs() <= (b - cur).abs() ? a : b,
      );
    }
    _animateSheet(target);
  }

  // ── 선택 ──────────────────────────────────────────────────────────────

  EmptyClass? _buildingOf(String? name) {
    if (name == null) return null;
    for (final e in ref.read(emptyClassesProvider).valueOrNull ?? const []) {
      if (e.className == name) return e;
    }
    return null;
  }

  void _moveCamera(double lat, double lng) {
    try {
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: NLatLng(lat, lng))..setAnimation(
          animation: NCameraAnimation.easing,
          duration: const Duration(milliseconds: 300),
        ),
      );
    } catch (_) {}
  }

  void _selectBuilding(String? name) {
    if (name == _buildingName) return;
    setState(() => _buildingName = name);
    _refreshMarkers();
    final b = _buildingOf(name);
    if (b != null && b.hasLocation) _moveCamera(b.latitude!, b.longitude!);
  }

  void _openBuilding(EmptyClass b) {
    _selectBuilding(b.className);
    _show(_Panel.building);
  }

  /// 빈 강의실 현황을 열고, 시트가 다 올라오면 [building] 카드로 스크롤한다.
  Future<void> _openEmptyClass({String? building}) async {
    if (building != null) _selectBuilding(building);
    await _show(_Panel.emptyClass);
    if (mounted && building != null) {
      setState(() => _focusBuilding = building);
    }
  }

  void _setTukCategory(TukCategory? c) {
    setState(() => _tukCategory = c);
    _refreshMarkers();
    _animateSheet(_fracOf(_Panel.tuk, c));
  }

  void _selectPlace(TukPlace? p) {
    setState(() => _place = p);
    _refreshMarkers();
    if (p != null) _moveCamera(p.latitude, p.longitude);
  }

  void _openPlace(TukPlace p) {
    _selectPlace(p);
    _show(_Panel.tukDetail);
  }

  void _onSearchPick(Object item) {
    _search.clear();
    _searchFocus.unfocus();
    switch (item) {
      case EmptyClass b:
        _openBuilding(b);
      case TukPlace p:
        _openPlace(p);
    }
  }

  /// 홈에서 넘어온 건물 요청이 있으면 그 건물의 빈 강의실 현황을 연다.
  /// 데이터·지도·시트가 모두 준비된 뒤에 호출돼야 하므로 여러 시점에서 시도한다.
  void _consumeFocus(List<EmptyClass> items) {
    final name = ref.read(emptyClassFocusControllerProvider);
    if (name == null || !items.any((e) => e.className == name)) return;
    ref.read(emptyClassFocusControllerProvider.notifier).consume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openEmptyClass(building: name);
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _initialCamera = NCameraPosition(
        target: NLatLng(pos.latitude, pos.longitude),
        zoom: 17.0,
      );
      if (!mounted) return;
      // 권한이 확보된 시점이므로 내 위치 오버레이(파란 점)도 켠다.
      _mapController?.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      _moveCamera(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  // ── 마커 ──────────────────────────────────────────────────────────────

  /// 탭에 맞는 마커를 다시 그린다. 교내시설은 건물(빈 강의실 수),
  /// TUK 월드는 고른 분류의 업체. 아이콘은 키별로 캐시한다.
  Future<void> _refreshMarkers() async {
    final gen = ++_markerGen;
    final markers = <NMarker>{};
    if (_panel.isTuk) {
      final category = _tukCategory ?? TukCategory.all;
      for (final p
          in ref.read(tukWorldPlacesProvider).valueOrNull ??
              const <TukPlace>[]) {
        if (!category.matches(p)) continue;
        final selected = p.id == _place?.id;
        final icon = TukCategory.iconOf(p);
        final key = 'p:${icon.codePoint}:$selected';
        final img =
            _iconCache[key] ??= await placeMarkerIcon(icon, selected: selected);
        if (gen != _markerGen) return;
        markers.add(
          NMarker(
              id: 'p${p.id}',
              position: NLatLng(p.latitude, p.longitude),
              icon: img.icon,
              anchor: img.anchor,
              size: img.size,
            )
            ..setGlobalZIndex(selected ? 400000 : 200000)
            ..setOnTapListener((_) => _openPlace(p)),
        );
      }
    } else {
      for (final b
          in ref.read(emptyClassesProvider).valueOrNull ??
              const <EmptyClass>[]) {
        // 좌표 테이블에 없는 건물은 목록에만 나온다.
        if (!b.hasLocation) continue;
        final selected = b.className == _buildingName;
        final tipRight = b.className == _tipRightBuilding;
        final key = 'b:${b.className}:${b.emptyCount}:$selected';
        final img =
            _iconCache[key] ??= await buildingMarkerIcon(
              b.className,
              b.emptyCount,
              selected: selected,
              tipRight: tipRight,
            );
        if (gen != _markerGen) return;
        markers.add(
          NMarker(
              id: 'b${b.className}',
              position: NLatLng(b.latitude!, b.longitude!),
              icon: img.icon,
              anchor: img.anchor,
              size: img.size,
            )
            // 고른 마커가 다른 마커에 가려지지 않게 위로 올린다.
            ..setGlobalZIndex(selected ? 400000 : 200000)
            ..setOnTapListener((_) => _openBuilding(b)),
        );
      }
    }
    final controller = _mapController;
    if (gen != _markerGen || !mounted || controller == null) return;
    // 네이버 지도는 마커를 위젯 속성이 아닌 컨트롤러로 관리한다.
    try {
      await controller.clearOverlays(type: NOverlayType.marker);
      await controller.addOverlayAll(markers);
    } catch (_) {}
  }

  // ── 화면 ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 데이터가 갱신되면 마커도 갱신 (최초 반영은 onMapReady에서)
    ref.listen(emptyClassesProvider, (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      _refreshMarkers();
      _consumeFocus(data);
    });
    // 이미 열려 있는 상태에서 홈이 건물을 넘겨도 반응한다.
    ref.listen(emptyClassFocusControllerProvider, (_, name) {
      final data = ref.read(emptyClassesProvider).valueOrNull;
      if (name != null && data != null) _consumeFocus(data);
    });
    if (_panel.isTuk) {
      ref.listen(tukWorldPlacesProvider, (_, _) => _refreshMarkers());
    }
    final refreshing = ref.watch(
      emptyClassesProvider.select((a) => a.isLoading && a.hasValue),
    );

    return PopScope(
      canPop: _panel == _Panel.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      // 앱바가 없어 이전 화면의 상태바 스타일이 남으므로 밝은 지도용으로 지정한다.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: SandolColors.background,
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, c) => _buildStack(c.maxHeight, refreshing),
          ),
        ),
      ),
    );
  }

  Widget _buildStack(double bodyH, bool refreshing) {
    final topInset = MediaQuery.of(context).padding.top;
    final minFrac = _minFrac(bodyH);
    return Stack(
      children: [
        Positioned.fill(
          child:
              widget.mapOverride ??
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: _initialCamera,
                  mapType: NMapType.basic,
                  locationButtonEnable: false,
                  contentPadding: EdgeInsets.only(
                    bottom: _collapsedH,
                    top: topInset + 110,
                  ),
                ),
                onMapReady: (c) {
                  _mapController = c;
                  _refreshMarkers();
                  final data = ref.read(emptyClassesProvider).valueOrNull;
                  if (data != null) _consumeFocus(data);
                },
              ),
        ),
        Positioned(
          top: topInset + 12,
          left: SandolMetrics.pageGutter,
          right: SandolMetrics.pageGutter,
          child: _TopBar(
            search: _search,
            focus: _searchFocus,
            tuk: _panel.isTuk,
            onTab: (tuk) => _show(tuk ? _Panel.tuk : _Panel.home),
            onChanged: () => setState(() {}),
            onPick: _onSearchPick,
          ),
        ),
        // 시트 높이에 따라 달라지는 것들은 시트 컨트롤러에만 반응하게 해
        // 드래그가 화면 전체 리빌드로 번지지 않게 한다.
        AnimatedBuilder(
          animation: _sheetCtrl,
          builder: (context, child) {
            final frac = _sheetCtrl.isAttached ? _sheetCtrl.size : minFrac;
            final hidden = frac > _coverFrac - 0.1;
            return Positioned(
              bottom: frac * bodyH + 12,
              left: SandolMetrics.pageGutter,
              child: IgnorePointer(
                ignoring: hidden,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: hidden ? 0.0 : 1.0,
                  child: child!,
                ),
              ),
            );
          },
          child: Column(
            spacing: SandolSpacing.sm,
            children: [
              _RoundButton(
                tooltip: '표시할 시설 선택',
                icon: Icons.tune_rounded,
                color: SandolColors.muted,
                onTap:
                    () =>
                        _panel.isTuk
                            ? _setTukCategory(null)
                            : _show(_Panel.filter),
              ),
              _RoundButton(
                tooltip: '내 위치',
                icon: Icons.my_location_rounded,
                onTap: _goToMyLocation,
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _sheetCtrl,
          builder: (context, _) {
            final frac = _sheetCtrl.isAttached ? _sheetCtrl.size : minFrac;
            return _MapCover(
              visible: frac > _coverFrac,
              onTap: () => _animateSheet(_snapFrac),
            );
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            controller: _sheetCtrl,
            minChildSize: minFrac,
            initialChildSize: _fracOf(_Panel.home, null),
            maxChildSize: _maxFrac,
            snap: true,
            snapSizes: const [_snapFrac],
            builder: (context, sc) => _buildSheet(sc, minFrac, bodyH),
          ),
        ),
        // 구간을 바꿔 다시 불러오는 동안의 작은 표시. 투명하게 숨기면 진행
        // 표시가 계속 돌아 프레임을 그리므로 갱신 중일 때만 만든다.
        if (refreshing)
          Positioned(
            top: topInset + 12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: SandolCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: SandolIconLabel(
                    icon: const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: SandolColors.primary,
                      ),
                    ),
                    label: '빈 강의실 갱신 중',
                    style: SandolTypography.caption,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSheet(ScrollController sc, double minFrac, double bodyH) {
    final building = _buildingOf(_buildingName);
    final place = _place;
    final Widget content = switch (_panel) {
      _Panel.home => CampusHomePanel(
        controller: sc,
        onEmptyClass: _openEmptyClass,
        onShowAll: () => _show(_Panel.filter),
      ),
      _Panel.filter => FacilityFilterPanel(
        controller: sc,
        onClose: () => _show(_Panel.home),
        onEmptyClass: _openEmptyClass,
      ),
      _Panel.building ||
      _Panel.buildingDetail when building != null => BuildingPanel(
        controller: sc,
        building: building,
        expanded: _panel == _Panel.buildingDetail,
        onDirections:
            building.hasLocation
                ? () => openDirections(
                  context,
                  name: building.className,
                  latitude: building.latitude!,
                  longitude: building.longitude!,
                )
                : null,
        onDetail: () => _show(_Panel.buildingDetail),
        onEmptyClass: () => _openEmptyClass(building: building.className),
      ),
      _Panel.emptyClass => EmptyClassPanel(
        controller: sc,
        focusBuilding: _focusBuilding,
        onBack: _back,
        onBuildingTap: _openBuilding,
      ),
      _Panel.tukDetail when place != null => TukPlaceDetail(
        controller: sc,
        place: place,
        onBack: _back,
        onDirections:
            () => openDirections(
              context,
              name: place.name,
              latitude: place.latitude,
              longitude: place.longitude,
            ),
        onShowOnMap: () {
          _moveCamera(place.latitude, place.longitude);
          _animateSheet(minFrac);
        },
      ),
      _Panel.tuk || _Panel.tukDetail => TukWorldPanel(
        controller: sc,
        category: _tukCategory,
        onCategory: _setTukCategory,
        onPlaceTap: _openPlace,
      ),
      // 데이터가 다시 불러와지며 고른 건물이 사라진 경우
      _Panel.building || _Panel.buildingDetail => CampusHomePanel(
        controller: sc,
        onEmptyClass: _openEmptyClass,
        onShowAll: () => _show(_Panel.filter),
      ),
    };

    return Material(
      color: SandolColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: SandolMetrics.radiusTop,
        side: BorderSide(color: MapColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => _onGripDragUpdate(d, minFrac, bodyH),
            onVerticalDragEnd: (d) => _onGripDragEnd(d, minFrac, bodyH),
            child: const Padding(
              padding: EdgeInsets.only(top: 7, bottom: SandolSpacing.sm),
              child: Center(child: _Grip()),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// 장소 검색창 + 교내시설/TUK 월드 탭 (2451:1122 상단).
/// 검색어가 있으면 건물 · TUK 월드 업체 중 이름이 맞는 곳을 아래에 띄운다.
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.search,
    required this.focus,
    required this.tuk,
    required this.onTab,
    required this.onChanged,
    required this.onPick,
  });

  final TextEditingController search;
  final FocusNode focus;
  final bool tuk;
  final ValueChanged<bool> onTab;
  final VoidCallback onChanged;

  /// [EmptyClass] 또는 [TukPlace]
  final ValueChanged<Object> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = search.text.trim();
    final results = <(String, String, Object)>[];
    if (q.isNotEmpty && focus.hasFocus) {
      for (final b
          in ref.watch(emptyClassesProvider).valueOrNull ??
              const <EmptyClass>[]) {
        if (b.className.contains(q)) {
          results.add((b.className, '빈 강의실 ${b.emptyCount}개', b));
        }
      }
      // TUK 월드는 검색할 때만 불러온다. 실패하면 건물만 보여준다.
      for (final p
          in ref.watch(tukWorldPlacesProvider).valueOrNull ??
              const <TukPlace>[]) {
        if (p.name.contains(q)) {
          results.add((p.name, 'TUK 월드 · ${p.category ?? '제휴'}', p));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: SandolColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: SandolMetrics.radius,
            side: BorderSide(color: MapColors.line),
          ),
          child: SizedBox(
            height: 51,
            child: TextField(
              controller: search,
              focusNode: focus,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              style: SandolTypography.caption,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '장소를 검색하세요',
                hintStyle: SandolTypography.caption.muted,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: SandolColors.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
              ),
            ),
          ),
        ),
        if (q.isNotEmpty && focus.hasFocus)
          Padding(
            padding: const EdgeInsets.only(top: SandolSpacing.xs),
            child: SandolCard(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child:
                    results.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(SandolSpacing.md),
                          child: Text(
                            '검색 결과가 없어요',
                            style: SandolTypography.caption.muted,
                          ),
                        )
                        : ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            for (final (title, sub, item) in results)
                              ListTile(
                                dense: true,
                                title: Text(
                                  title,
                                  style: SandolTypography.body,
                                ),
                                subtitle: Text(
                                  sub,
                                  style: SandolTypography.caption.muted,
                                ),
                                onTap: () => onPick(item),
                              ),
                          ],
                        ),
              ),
            ),
          )
        else ...[
          const SizedBox(height: SandolSpacing.sm),
          Row(
            spacing: 29,
            children: [
              Expanded(
                child: _Tab(
                  label: '교내시설',
                  selected: !tuk,
                  onTap: () => onTab(false),
                ),
              ),
              Expanded(
                child: _Tab(
                  label: 'TUK 월드',
                  selected: tuk,
                  onTap: () => onTab(true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: MapButton(label: label, primary: selected, onTap: onTap),
  );
}

/// 지도 왼쪽 원형 버튼 (46x46, 2451:1122 Frame 2147235235/6)
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = SandolColors.text,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: SandolColors.background,
    shape: const CircleBorder(side: BorderSide(color: MapColors.line)),
    elevation: 2,
    child: IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 46, height: 46),
      icon: Icon(icon, size: 22, color: color),
      onPressed: onTap,
    ),
  );
}

/// 시트가 거의 전체로 올라왔을 때 지도를 덮는 어두운 막 + '지도' 라벨 (2158:1177).
class _MapCover extends StatelessWidget {
  const _MapCover({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: GestureDetector(
          onTap: onTap,
          child: ColoredBox(
            // main20 + text20 을 지도 위에 겹친 색
            color: const Color(0x333882D3),
            child: ColoredBox(
              color: const Color(0x33040404),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Text('지도', style: SandolTypography.title.onPrimary),
                      const SizedBox(height: 7),
                      const _Grip(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 시트 손잡이 (2451:1122 Vector 5, 42x8)
class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 42,
    height: 8,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: MapColors.line,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
  );
}
