import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_radius.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/component/classroom_time_range_picker.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 빈 강의실 탭 (Figma 2158:806 · 2158:1177).
///
/// 지도와 마커는 그대로 두고, 아래 시트만 새 디자인이다. 시트는 세 높이
/// (접힘 · 중간 · 거의 전체)로 멈추고, 거의 전체일 때는 지도 위를 어둡게
/// 덮어 '지도' 라벨을 보여준다. 누르면 시트가 내려간다.
class EmptyDetailScreen extends ConsumerStatefulWidget {
  const EmptyDetailScreen({super.key});

  @override
  ConsumerState<EmptyDetailScreen> createState() => _EmptyDetailScreenState();
}

class _EmptyDetailScreenState extends ConsumerState<EmptyDetailScreen> {
  /// 시트 높이 3단. 접힘 높이만 픽셀 기준이라 화면 비율로 환산해 쓴다.
  static const _collapsedH = 120.0;
  static const _snapFrac = 0.42;
  static const _maxFrac = 0.9;

  /// 이보다 높이 올라가면 지도를 덮고 '지도' 라벨을 보여준다.
  static const _coverFrac = 0.7;

  /// 마커 탭으로 카드를 보여줄 때 올리는 높이 (드래그 스냅보다 한 단 높게)
  static const _revealFrac = 0.6;

  Set<NMarker> _markers = {};
  String? _selectedId;

  /// 마커 아이콘 캐시. 항목은 플러그인이 만든 임시 파일 경로와 앵커·크기뿐이라
  /// 메모리는 수십 바이트 단위다. 화면과 함께 사라지므로 상한을 두지 않는다
  /// (상한을 두면 재진입 시 3배 스케일 래스터화를 다시 하게 된다).
  final Map<String, ({NOverlayImage icon, NPoint anchor, Size size})>
  _iconCache = {};
  int _markerGen = 0;

  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();
  // 건물 카드로 정확히 스크롤(ensureVisible)하기 위한 카드 키 (건물명 → key)
  final Map<String, GlobalKey> _cardKeys = {};

  NaverMapController? _mapController;
  NCameraPosition _initialCamera = const NCameraPosition(
    target: NLatLng(37.34019, 126.7336),
    zoom: 17.0,
  );

  @override
  void dispose() {
    _iconCache.clear();
    _sheetCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCameraToMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final cam = NCameraPosition(
        target: NLatLng(pos.latitude, pos.longitude),
        zoom: 17.0,
      );
      _initialCamera = cam;
      if (mounted) {
        try {
          // 권한이 확보된 시점이므로 내 위치 오버레이(파란 점)도 켠다.
          _mapController?.setLocationTrackingMode(
            NLocationTrackingMode.noFollow,
          );
          _mapController?.updateCamera(
            NCameraUpdate.scrollAndZoomTo(target: cam.target, zoom: cam.zoom)
              ..setAnimation(
                animation: NCameraAnimation.easing,
                duration: const Duration(milliseconds: 500),
              ),
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _refreshMarkers(List<EmptyClass> data) async {
    _markerGen++;
    final gen = _markerGen;
    final markers = <NMarker>{};

    for (final e in data) {
      if (gen != _markerGen) return;
      // 좌표 테이블에 없는 건물은 목록에만 나온다.
      if (!e.hasLocation) continue;
      final name = e.className.replaceAll(':', '').trim();
      final selected = e.className == _selectedId;
      final key = '$name:${e.classCount}:${selected ? 1 : 0}';
      final iconData =
          _iconCache[key] ??
          await _buildCustomMarkerIcon(name, e.classCount, selected: selected);
      _iconCache[key] = iconData;

      final marker = NMarker(
        id: e.className,
        position: NLatLng(e.latitude!, e.longitude!),
        icon: iconData.icon,
        anchor: iconData.anchor,
        size: iconData.size,
      );
      // 선택된 마커가 다른 마커에 가려지지 않게 위로 올린다.
      marker.setGlobalZIndex(selected ? 400000 : 200000);
      marker.setOnTapListener((_) => _selectBuilding(e, reveal: true));
      markers.add(marker);
    }

    if (gen != _markerGen || !mounted) return;
    setState(() => _markers = markers);
    _applyMarkersToMap();
  }

  /// 네이버 지도는 마커를 위젯 속성이 아닌 컨트롤러로 관리하므로
  /// 마커 셋이 바뀔 때마다 지도에 다시 반영한다.
  Future<void> _applyMarkersToMap() async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.clearOverlays(type: NOverlayType.marker);
      await controller.addOverlayAll(_markers);
    } catch (_) {}
  }

  /// 건물 선택 공통 처리. 마커 탭(reveal=true)이면 시트를 스냅 높이까지
  /// 올리고 해당 카드로 스크롤, 리스트 탭(reveal=false)이면 지도만 이동.
  void _selectBuilding(EmptyClass e, {required bool reveal}) {
    setState(() => _selectedId = e.className);
    final data = ref.read(emptyClassesProvider).valueOrNull;
    if (data != null) _refreshMarkers(data);
    if (!e.hasLocation) {
      if (reveal) _revealCard(e.className);
      return;
    }
    try {
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(e.latitude!, e.longitude!),
        )..setAnimation(
          animation: NCameraAnimation.easing,
          duration: const Duration(milliseconds: 300),
        ),
      );
    } catch (_) {}
    if (reveal) _revealCard(e.className);
  }

  /// 시트를 리빌 높이까지 올린 뒤 해당 건물 카드가 보이도록 스크롤한다.
  Future<void> _revealCard(String className) async {
    try {
      if (_sheetCtrl.isAttached && _sheetCtrl.size < _revealFrac - 0.01) {
        await _sheetCtrl.animateTo(
          _revealFrac,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      final ctx = _cardKeys[className]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }

  /// 홈에서 넘어온 건물 요청이 있으면 그 건물을 선택하고 시트를 올린다.
  /// 데이터·지도·시트가 모두 준비된 뒤에 호출돼야 하므로 여러 시점에서 시도한다.
  void _consumeFocus(List<EmptyClass> items) {
    final name = ref.read(emptyClassFocusControllerProvider);
    if (name == null) return;
    EmptyClass? target;
    for (final e in items) {
      if (e.className == name) {
        target = e;
        break;
      }
    }
    if (target == null) return;
    ref.read(emptyClassFocusControllerProvider.notifier).consume();
    final t = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectBuilding(t, reveal: true);
    });
  }

  double _minFrac(double screenH) =>
      (_collapsedH / screenH).clamp(0.08, 0.35).toDouble();

  // 헤더는 스크롤러블 밖에 있으므로 시트 컨트롤러를 직접 구동한다.
  // 리스트가 어디까지 스크롤돼 있든 헤더 드래그는 항상 시트를 움직인다.
  void _onHeaderDragUpdate(
    DragUpdateDetails d,
    double minFrac,
    double screenH,
  ) {
    if (!_sheetCtrl.isAttached) return;
    _sheetCtrl.jumpTo(
      (_sheetCtrl.size - d.delta.dy / screenH).clamp(minFrac, _maxFrac),
    );
  }

  void _onHeaderDragEnd(DragEndDetails d, double minFrac, double screenH) {
    if (!_sheetCtrl.isAttached) return;
    final v = -d.velocity.pixelsPerSecond.dy / screenH; // 위로 드래그가 양수
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
    _sheetCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    StatefulNavigationShell.of(context).goBranch(RootShell.homeBranch);
  }

  /// 건물명 + 빈 강의실 개수(원형 숫자 배지)를 표시하는 커스텀 마커 비트맵.
  /// 앱 컬러 토큰만 사용한다: 잔여 있음 = primary, 없음 = muted 회색,
  /// 선택된 건물은 primary 반전 + 헤일로로 지도 위에서 바로 구분된다.
  static Future<({NOverlayImage icon, NPoint anchor, Size size})>
  _buildCustomMarkerIcon(
    String name,
    String count, {
    required bool selected,
  }) async {
    const double scale = 3.0;
    const double padH = 11.0;
    const double padV = 7.0;
    const double gap = 7.0;
    const double tipH = 8.0;
    const double tipHalfW = 6.0;
    const double shadowBlur = 6.0;
    const double badgePadH = 6.0;
    const double badgePadV = 3.0;
    const double haloW = 2.5;
    const Color primary = AppColors.primary;

    final int roomCount = int.tryParse(count) ?? 0;
    final bool hasRooms = roomCount > 0;

    // 잔여 있음 = primary, 없음 = muted.
    final Color accent = hasRooms ? primary : AppColors.textMuted;

    final Color nameColor = selected ? Colors.white : AppColors.textPrimary;
    final Color badgeBg = selected ? Colors.white : accent;
    final Color badgeFg = selected ? primary : Colors.white;

    final nameTp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: nameColor,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 숫자만 크게 — "개"는 리스트 패널이 이미 말해주므로 지도에선 수치가 핵심.
    final countTp = TextPainter(
      text: TextSpan(
        text: '$roomCount',
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w800,
          color: badgeFg,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 한 자리 수는 정원, 두 자리 이상은 알약형으로 늘어나는 배지
    final double badgeH = countTp.height + badgePadV * 2;
    final double badgeW = math.max(countTp.width + badgePadH * 2, badgeH);
    final double contentH = math.max(nameTp.height, badgeH);
    final double pillH = contentH + padV * 2;
    final double radius = pillH / 2; // 캡슐형
    final double pillW = padH + nameTp.width + gap + badgeW + padH;

    // 헤일로 + 그림자 블러가 잘리지 않도록 여백 확보
    const double m = shadowBlur * 2 + haloW;
    const double ox = m;
    const double oy = m;
    final double canvasW = pillW + m * 2;
    final double canvasH = pillH + tipH + m * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasW * scale, canvasH * scale),
    );
    canvas.scale(scale);

    // 말풍선(캡슐 + 꼬리)을 하나의 패스로 합쳐 외곽선이 매끄럽게 이어지게 한다.
    Path bubblePath(double inflate) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          ox - inflate,
          oy - inflate,
          pillW + inflate * 2,
          pillH + inflate * 2,
        ),
        Radius.circular(radius + inflate),
      );
      final tipX = ox + pillW / 2;
      final tip =
          Path()
            ..moveTo(tipX - tipHalfW - inflate, oy + pillH - radius / 2)
            ..lineTo(tipX + tipHalfW + inflate, oy + pillH - radius / 2)
            ..lineTo(tipX, oy + pillH + tipH + inflate)
            ..close();
      return Path.combine(PathOperation.union, Path()..addRRect(rrect), tip);
    }

    final bubble = bubblePath(0);

    // 선택 헤일로
    if (selected) {
      canvas.drawPath(
        bubblePath(haloW),
        Paint()..color = primary.withValues(alpha: 0.28),
      );
    }

    // 2겹 그림자: 넓게 퍼지는 ambient + 경계를 잡아주는 key
    canvas.drawPath(
      bubble.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: selected ? 0.20 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, shadowBlur),
    );
    canvas.drawPath(
      bubble.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // 말풍선 본체 (미세한 세로 그라데이션으로 평면감 제거)
    final Paint pillPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, oy),
            Offset(0, oy + pillH + tipH),
            selected
                ? [
                  Color.lerp(primary, Colors.white, 0.14)!,
                  Color.lerp(primary, Colors.black, 0.08)!,
                ]
                : [Colors.white, const Color(0xFFF5FAFD)],
          );
    canvas.drawPath(bubble, pillPaint);

    // 외곽선 (선택 시에는 배경색이 곧 브랜드 컬러라 생략)
    if (!selected) {
      canvas.drawPath(
        bubble,
        Paint()
          ..color = AppColors.cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // 건물명
    final double nameX = ox + padH;
    nameTp.paint(canvas, Offset(nameX, oy + (pillH - nameTp.height) / 2));

    // 개수 배지
    final double badgeX = nameX + nameTp.width + gap;
    final double badgeY = oy + (pillH - badgeH) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(AppRadius.value),
      ),
      Paint()..color = badgeBg,
    );
    countTp.paint(
      canvas,
      Offset(
        badgeX + (badgeW - countTp.width) / 2,
        badgeY + (badgeH - countTp.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (canvasW * scale).round(),
      (canvasH * scale).round(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = await NOverlayImage.fromByteArray(
      byteData!.buffer.asUint8List(),
    );

    // 꼬리 끝(지리 위치)에 앵커 설정
    final double anchorX = (ox + pillW / 2) / canvasW;
    final double anchorY = (oy + pillH + tipH) / canvasH;
    return (
      icon: icon,
      anchor: NPoint(anchorX, anchorY),
      // 3배 스케일로 그린 비트맵이므로 마커 크기를 논리 크기로 고정한다.
      size: Size(canvasW, canvasH),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minFrac = _minFrac(size.height);
    final classesAsync = ref.watch(emptyClassesProvider);

    // 데이터가 갱신되면 마커도 갱신 (최초 반영은 onMapReady에서)
    ref.listen(emptyClassesProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null) {
        _refreshMarkers(data);
        _consumeFocus(data);
      }
    });
    // 이미 열려 있는 상태에서 홈이 건물을 넘겨도 반응한다.
    ref.listen(emptyClassFocusControllerProvider, (_, name) {
      final data = classesAsync.valueOrNull;
      if (name != null && data != null) _consumeFocus(data);
    });

    final items = classesAsync.valueOrNull;
    return Scaffold(
      backgroundColor: SandolColors.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      // 구간을 바꿔 다시 불러올 때도 지도와 시트를 그대로 둔다.
      // when() 으로 로딩 화면을 끼워 넣으면 Stack 이 통째로 다시 만들어져
      // 시트가 접힌 위치로 돌아가고 지도도 초기화된다.
      body:
          items == null
              ? classesAsync.hasError
                  ? ErrorRetryView(
                    title: '빈 강의실 정보를 불러오지 못했어요',
                    onRetry: () => ref.invalidate(emptyClassesProvider),
                  )
                  : const Center(child: SandolLoadingIndicator())
              : _buildStack(
                items,
                size,
                minFrac,
                refreshing: classesAsync.isLoading,
              ),
    );
  }

  Widget _buildStack(
    List<EmptyClass> items,
    Size size,
    double minFrac, {
    required bool refreshing,
  }) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: _initialCamera,
              mapType: NMapType.basic,
              locationButtonEnable: false,
              contentPadding: EdgeInsets.only(
                bottom: _collapsedH,
                top: topInset,
              ),
            ),
            onMapReady: (c) {
              _mapController = c;
              _refreshMarkers(items);
              _consumeFocus(items);
            },
          ),
        ),
        // 시트 높이에 따라 달라지는 것들은 시트 컨트롤러에만 반응하게 해
        // 드래그가 화면 전체 리빌드로 번지지 않게 한다.
        AnimatedBuilder(
          animation: _sheetCtrl,
          builder: (context, _) {
            final frac = _sheetCtrl.isAttached ? _sheetCtrl.size : minFrac;
            return _MapCover(
              visible: frac > _coverFrac,
              onTap:
                  () => _sheetCtrl.animateTo(
                    _snapFrac,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  ),
            );
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            controller: _sheetCtrl,
            minChildSize: minFrac,
            // 시안의 기본 상태는 중간 높이(지도 + 첫 건물 카드)
            initialChildSize: _snapFrac,
            maxChildSize: _maxFrac,
            snap: true,
            snapSizes: const [_snapFrac],
            builder:
                (context, sc) => _buildSheet(items, sc, minFrac, size.height),
          ),
        ),
        AnimatedBuilder(
          animation: _sheetCtrl,
          builder: (context, child) {
            final frac = _sheetCtrl.isAttached ? _sheetCtrl.size : minFrac;
            final hidden = frac > _coverFrac - 0.1;
            return Positioned(
              bottom: frac * size.height + 12,
              right: 12,
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
          child: FloatingActionButton(
            backgroundColor: SandolColors.background,
            foregroundColor: SandolColors.text,
            elevation: 4,
            onPressed: _initCameraToMyLocation,
            child: const Icon(Icons.my_location_rounded, size: 24),
          ),
        ),
        // 구간 변경으로 다시 불러오는 동안의 작은 표시
        Positioned(
          top: topInset + 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: refreshing ? 1 : 0,
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
        ),
      ],
    );
  }

  Widget _buildSheet(
    List<EmptyClass> items,
    ScrollController sc,
    double minFrac,
    double screenH,
  ) {
    final totalRooms = items.fold<int>(0, (s, e) => s + e.emptyCount);
    final query = ref.watch(classroomQueryControllerProvider);

    return Material(
      color: SandolColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: SandolMetrics.radiusTop,
        side: BorderSide(color: SandolColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더: 리스트 스크롤 위치와 무관하게 항상 시트를 끌 수 있다.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate:
                (d) => _onHeaderDragUpdate(d, minFrac, screenH),
            onVerticalDragEnd: (d) => _onHeaderDragEnd(d, minFrac, screenH),
            child: _SheetHeader(
              subtitle: '${query.dayName} ${query.timeLabel} 동안 비어 있는 강의실',
              buildings: items.length,
              rooms: totalRooms,
              onBack: _handleBack,
              onSubtitleTap: () => showClassroomTimeSheet(context),
            ),
          ),
          Expanded(
            child:
                items.isEmpty
                    ? Center(
                      child: Text(
                        '현재 빈 강의실이 없습니다.',
                        style: SandolTypography.caption.muted,
                      ),
                    )
                    : ListView.separated(
                      controller: sc,
                      // 카드가 미리 빌드돼 있어야 ensureVisible 스크롤이
                      // 항상 정확히 동작한다 (건물 수십 개 수준이라 부담 없음).
                      cacheExtent: 4000,
                      padding: const EdgeInsets.fromLTRB(
                        SandolMetrics.pageGutter,
                        SandolSpacing.md,
                        SandolMetrics.pageGutter,
                        SandolSpacing.xl,
                      ),
                      itemCount: items.length,
                      separatorBuilder:
                          (_, _) => const SizedBox(height: SandolSpacing.lg),
                      itemBuilder: (_, idx) {
                        final item = items[idx];
                        return KeyedSubtree(
                          key: _cardKeys.putIfAbsent(
                            item.className,
                            GlobalKey.new,
                          ),
                          child: _BuildingCard(
                            item: item,
                            selected: item.className == _selectedId,
                            onTap: () => _selectBuilding(item, reveal: false),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
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

/// 시트 손잡이 (2158:1410)
class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 42.5,
    height: 8,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: SandolColors.inactive,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
  );
}

/// 손잡이 · 뒤로가기 + 제목 · 조회 구간 + 동/개수 (2158:811 상단)
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.subtitle,
    required this.buildings,
    required this.rooms,
    required this.onBack,
    required this.onSubtitleTap,
  });

  final String subtitle;
  final int buildings;
  final int rooms;
  final VoidCallback onBack;

  /// 조회 구간 문구를 누르면 시간 설정 시트가 열린다.
  final VoidCallback onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    final stat = SandolTypography.caption.strong.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        5,
        SandolMetrics.pageGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _Grip()),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                borderRadius: SandolMetrics.radius,
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.all(SandolSpacing.xs),
                  child: SvgPicture.asset(SandolAssets.backArrow),
                ),
              ),
              const SizedBox(width: 11),
              const Text('빈 강의실 현황', style: SandolTypography.title),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: SandolMetrics.radius,
                  onTap: onSubtitleTap,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SandolTypography.caption.muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$buildings동', style: stat),
              const SizedBox(width: 12),
              Text('총 $rooms개', style: stat),
            ],
          ),
        ],
      ),
    );
  }
}

/// 건물 한 장: 건물명 · 개수 · 층별 강의실 칩 (2158:815)
class _BuildingCard extends StatelessWidget {
  const _BuildingCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final EmptyClass item;

  /// 마커로 고른 건물. 개수를 강조색 굵은 글씨로 보여준다(2158:1194).
  final bool selected;
  final VoidCallback onTap;

  static String _floorOf(String room) {
    final m = RegExp(r'\d').firstMatch(room);
    return m == null ? '기타' : '${m.group(0)}층';
  }

  @override
  Widget build(BuildContext context) {
    final floors = <String, List<String>>{};
    for (final room in item.classList) {
      floors.putIfAbsent(_floorOf(room), () => []).add(room);
    }
    final sortedFloors =
        floors.keys.toList()..sort((a, b) {
          if (a == '기타') return 1;
          if (b == '기타') return -1;
          return a.compareTo(b);
        });

    return SandolCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(11, 24, 19, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SandolSpacing.md,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SandolTypography.title.accent,
                ),
              ),
              Text(
                '${item.emptyCount}개',
                style:
                    selected
                        ? SandolTypography.body.strong.accent
                        : SandolTypography.body.copyWith(
                          color: SandolColors.textSecondary,
                        ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SandolSpacing.sm,
            children: [
              for (final floor in sortedFloors) ...[
                SandolIconLabel(
                  icon: SvgPicture.asset(SandolAssets.floor),
                  label: floor,
                  style: SandolTypography.caption,
                  gap: 5,
                ),
                Wrap(
                  spacing: SandolSpacing.sm,
                  runSpacing: SandolSpacing.sm,
                  children: [
                    for (final room in floors[floor]!) _RoomChip(room),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip(this.room);

  final String room;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: SandolSpacing.xs,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: SandolMetrics.radius,
    ),
    child: Text(room, style: SandolTypography.caption),
  );
}
