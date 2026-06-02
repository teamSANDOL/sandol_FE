import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:handori/common/layout/root_tab.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/bus/presentation/widget/realtime_bus_arrival_section.dart';

// ─── Color tokens ──────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF00C4F9); // 핀포인트 전용
const Color _kBgBase = Colors.white;
const Color _kBgSoft = Color(0xFFFAFAFA);
const Color _kBorderSoft = Color(0xFFF0F0F8);
const Color _kTextPrimary = Color(0xFF1A1A1A);
const Color _kTextMuted = Color(0xFF8A8F98);

// ─── Layout tokens ─────────────────────────────────────────────────────────
const double _kCardRadius = 12.0;
const double _kMinPanelHeight = 110.0;
const double _kMaxPanelHeight = 500.0;

// ─── Text styles ───────────────────────────────────────────────────────────
const TextStyle _kTitleLarge = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w800,
  color: _kTextPrimary,
  letterSpacing: -0.3,
);
const TextStyle _kSectionTitle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: _kTextMuted,
  letterSpacing: 0.4,
);
const TextStyle _kBusSubLabel = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w500,
  color: _kTextMuted,
  letterSpacing: -0.1,
);
const TextStyle _kArrivalUnit = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w600,
  color: _kTextMuted,
);

class BusTimeDetailScreen extends ConsumerStatefulWidget {
  const BusTimeDetailScreen({super.key});

  @override
  ConsumerState<BusTimeDetailScreen> createState() =>
      _BusTimeDetailScreenState();
}

class _BusTimeDetailScreenState extends ConsumerState<BusTimeDetailScreen> {
  // 학교(정문) 측 좌표 — 정왕역 방면 탑승 위치
  static const LatLng _schoolMainGate = LatLng(37.33896, 126.7335);
  static const LatLng _schoolShuttleStop = LatLng(37.33991, 126.7323);
  static const LatLng _schoolCenter = LatLng(37.339496586083, 126.73287520461);

  // 정왕역 측 좌표 — 학교 방면 탑승 위치
  static const LatLng _stationShuttleStop = LatLng(37.35174, 126.74288);
  static const LatLng _stationBusStop = LatLng(37.35194, 126.74258);
  static const LatLng _stationCenter = LatLng(37.35184, 126.74273);

  final CameraPosition _initialPosition = const CameraPosition(
    target: _schoolCenter,
    zoom: 17.6,
  );

  int _selectedDestination = 0; // 0: 정왕역 방면, 1: 학교 방면
  double _panelPos = 0.0;

  final PanelController _panelController = PanelController();
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 진입 시 패널을 최대 높이(_kMaxPanelHeight)까지 부드럽게 올림
      _panelController.animatePanelToPosition(
        1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // 현재 선택된 방면의 마커 세트
  Set<Marker> get _markers {
    if (_selectedDestination == 0) {
      // 정왕역 방면: 학교에서 탑승 → 학교 마커
      return {
        const Marker(
          markerId: MarkerId('school_main_gate'),
          position: _schoolMainGate,
          infoWindow: InfoWindow(title: '정문 버스 정류장'),
        ),
        Marker(
          markerId: const MarkerId('school_shuttle'),
          position: _schoolShuttleStop,
          infoWindow: const InfoWindow(
            title: '학교 셔틀버스 탑승장',
            snippet: '정왕역행 셔틀',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      };
    }
    // 학교 방면: 정왕역에서 탑승 → 정왕역 마커
    return {
      const Marker(
        markerId: MarkerId('station_bus_stop'),
        position: _stationBusStop,
        infoWindow: InfoWindow(title: '정왕역 버스 정류장'),
      ),
      Marker(
        markerId: const MarkerId('station_shuttle'),
        position: _stationShuttleStop,
        infoWindow: const InfoWindow(
          title: '정왕역 셔틀버스 탑승장',
          snippet: '학교행 셔틀',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    };
  }

  // 현재 방면의 셔틀 탑승 좌표
  LatLng get _currentShuttleStop =>
      _selectedDestination == 0 ? _schoolShuttleStop : _stationShuttleStop;

  // 현재 방면의 일반 버스 정류장 좌표
  LatLng get _currentBusStop =>
      _selectedDestination == 0 ? _schoolMainGate : _stationBusStop;

  // 현재 방면의 카메라 중심
  LatLng get _currentAreaCenter =>
      _selectedDestination == 0 ? _schoolCenter : _stationCenter;

  void _onDestinationChanged(int index) {
    if (_selectedDestination == index) return;
    setState(() => _selectedDestination = index);
    _focusTo(_currentAreaCenter, zoom: 17.4);
  }

  Future<void> _checkPermission() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) throw Exception('권한을 허가해주세요');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      throw Exception('위치 권한을 허가해 주세요 ');
    }
  }

  void _handleBack() {
    final shell = RootTab.of(context);
    if (shell != null) {
      shell.jumpTo(2);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onBellPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 버튼')),
    );
  }

  void _onUserPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('유저 버튼')),
    );
  }

  Future<void> _focusTo(LatLng target, {double zoom = 18}) async {
    try {
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {}
    // 방면 변경 시 패널이 내려가지 않도록 애니메이션 로직 제거
  }

  Future<void> _goToMyLocation() async {
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
      await _focusTo(LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkPermission(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('위치 권한을 허용해 주세요')),
          );
        }

        final fabBottom =
            _kMinPanelHeight +
            (_panelPos * (_kMaxPanelHeight - _kMinPanelHeight)) +
            12;

        return Scaffold(
          backgroundColor: _kBgBase,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Stack(
            children: [
              SlidingUpPanel(
                controller: _panelController,
                color: _kBgBase,
                maxHeight: _kMaxPanelHeight,
                minHeight: _kMinPanelHeight,
                panelSnapping: true,
                snapPoint: 0.55,
                parallaxEnabled: false,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
                onPanelSlide: (pos) => setState(() => _panelPos = pos),
                panelBuilder: (sc) => _BusInfoPanel(
                  scrollController: sc,
                  selectedDestination: _selectedDestination,
                  onDestinationChanged: _onDestinationChanged,
                  onShowMainGate: () => _focusTo(_currentBusStop),
                  onShowShuttle: () => _focusTo(_currentShuttleStop),
                ),
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _initialPosition,
                        onMapCreated: (c) => _mapController = c,
                        onTap: (_) => _panelController.close(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: _markers,
                        padding: EdgeInsets.only(
                          bottom: _kMinPanelHeight,
                          top: MediaQuery.of(context).padding.top + 60,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _ToolbarCard(
                          title: '버스조회',
                          onBack: _handleBack,
                          onBell: _onBellPressed,
                          onUser: _onUserPressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 50),
                curve: Curves.linear,
                bottom: fabBottom,
                right: 14,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _panelPos > 0.7 ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _panelPos > 0.7,
                    child: FloatingActionButton(
                      backgroundColor: _kBgBase,
                      foregroundColor: _kTextPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: _kBorderSoft),
                      ),
                      onPressed: _goToMyLocation,
                      child: const Icon(Icons.my_location_rounded, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Floating toolbar
// ───────────────────────────────────────────────────────────────────────────

class _ToolbarCard extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onBell;
  final VoidCallback onUser;

  const _ToolbarCard({
    required this.title,
    required this.onBack,
    required this.onBell,
    required this.onUser,
  });

  static final _kSubtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _kBgBase,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderSoft),
            boxShadow: _kSubtleShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onBack,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kTextPrimary,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: _kBgBase,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorderSoft),
              boxShadow: _kSubtleShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '알림',
                  onPressed: onBell,
                  icon: const Icon(Icons.notifications_none_rounded, size: 20),
                  color: _kTextMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: '내 정보',
                  onPressed: onUser,
                  icon: const Icon(Icons.account_circle_outlined, size: 22),
                  color: _kTextMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Bus info panel
// ───────────────────────────────────────────────────────────────────────────

class _BusInfoPanel extends ConsumerWidget {
  final ScrollController scrollController;
  final int selectedDestination;
  final ValueChanged<int> onDestinationChanged;
  final VoidCallback onShowMainGate;
  final VoidCallback onShowShuttle;

  const _BusInfoPanel({
    required this.scrollController,
    required this.selectedDestination,
    required this.onDestinationChanged,
    required this.onShowMainGate,
    required this.onShowShuttle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 방면별 라벨
    final isToStation = selectedDestination == 0;
    final shuttleRoute = isToStation ? '정왕역(셔틀)행' : '학교(셔틀)행';
    final stopSectionTitle = isToStation ? '정문 버스 정류장' : '정왕역 버스 정류장';
    // 토글 → 실시간 도착 정보를 조회할 정류장 ID 목록.
    //  - 정왕역 방면(학교에서 탑승)  = 정문 정류장 1곳
    //  - 학교 방면(정왕역에서 탑승)  = 정왕역 승차 정류장 2곳(25835, 25904)
    final stationIds = isToStation
        ? const [CampusBusStops.mainGate]
        : CampusBusStops.jeongwangStations;

    // 화면 토글 → 노선1(정왕역↔본교) 방향 매핑
    //  - 정왕역 방면(학교에서 탑승)  = 학교 → 정왕 (하교)
    //  - 학교 방면(정왕역에서 탑승)  = 정왕 → 학교 (등교)
    final direction = isToStation
        ? ShuttleDirection.schoolToJeongwang
        : ShuttleDirection.jeongwangToSchool;
    final nextShuttle = ref.watch(
      nextShuttleProvider(
        route: ShuttleRoute.route1,
        direction: direction,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 상단 고정 영역 ---
        // 핸들
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 22),
            decoration: BoxDecoration(
              color: _kBorderSoft,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: const Text('버스 시간표', style: _kTitleLarge),
        ),
        // 목적지 토글
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: _DestinationToggle(
            selected: selectedDestination,
            onChanged: onDestinationChanged,
          ),
        ),
        const SizedBox(height: 28),
        
        // --- 하단 스크롤 영역 ---
        Expanded(
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // 셔틀 정보
              _SectionHeader(
                title: '학교 셔틀버스',
                onAction: onShowShuttle,
                actionLabel: '위치 보기',
              ),
              const SizedBox(height: 14),
              _ShuttleCard(
                route: shuttleRoute,
                next: nextShuttle,
              ),
              const SizedBox(height: 36),
              // 일반 버스 정보
              _SectionHeader(
                title: stopSectionTitle,
                onAction: onShowMainGate,
                actionLabel: '위치 보기',
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < stationIds.length; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                RealtimeBusArrivalSection(
                  stationId: stationIds[i],
                  // 정류장이 2곳 이상일 때만 구분용 라벨을 표시한다.
                  label: stationIds.length > 1
                      ? '정류장 ${stationIds[i]}'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Sub components
// ───────────────────────────────────────────────────────────────────────────

class _DestinationToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DestinationToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _kBgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderSoft),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [_toggleItem('정왕역 방면', 0), _toggleItem('학교 방면', 1)]),
    );
  }

  Widget _toggleItem(String label, int index) {
    final bool isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? _kBgBase : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color:
                  isSelected
                      ? _kPrimary.withValues(alpha: 0.35)
                      : Colors.transparent,
              width: 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _kPrimary : _kTextMuted,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _SectionHeader({required this.title, this.onAction, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: _kSectionTitle),
          const Spacer(),
          if (onAction != null && actionLabel != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTextMuted,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _kTextMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// 공통 카드 컨테이너 (셔틀/일반 버스 공유)
class _RouteCard extends StatelessWidget {
  final Widget child;
  const _RouteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  // 임박 강조 기준(분) — 이 시간 이하면 핀포인트 블루로 강조.
  static const int _imminentThreshold = 15;

  final String route;
  final NextShuttle next;

  const _ShuttleCard({required this.route, required this.next});

  @override
  Widget build(BuildContext context) {
    final subText = next.subText;
    return _RouteCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _kBgSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorderSoft),
              ),
              child: const Icon(
                Icons.airport_shuttle_rounded,
                color: _kTextPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subText != null && subText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: _kBusSubLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ShuttleTrailing(
              next: next,
              imminentThreshold: _imminentThreshold,
            ),
          ],
        ),
      ),
    );
  }
}

/// 셔틀 카드 우측 표시 — 정시 출발은 분 카운트다운, 그 외(수시운행·도착버스
/// 탑승·운행 종료·운행 안함)는 상태 라벨로 렌더한다.
class _ShuttleTrailing extends StatelessWidget {
  final NextShuttle next;
  final int imminentThreshold;

  const _ShuttleTrailing({required this.next, required this.imminentThreshold});

  @override
  Widget build(BuildContext context) {
    final remain = next.remainMinutes;
    if (next.showsMinutes && remain != null && remain > 0) {
      return _ArrivalTime(
        minutes: '$remain',
        isImminent: remain <= imminentThreshold,
      );
    }

    // 정각 출발 직전(remain == 0) → "곧 도착", 그 외는 상태 라벨.
    final label = (next.status == ShuttleStatus.upcoming)
        ? '곧 도착'
        : (next.statusLabel ?? '-');
    final emphasize = next.status == ShuttleStatus.upcoming ||
        next.status == ShuttleStatus.flexible ||
        next.status == ShuttleStatus.arrivalBoarding;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: emphasize ? _kPrimary : _kTextMuted,
          letterSpacing: -0.3,
          height: 1.15,
        ),
      ),
    );
  }
}

/// 도착 시간 표시 — 색이 아닌 타이포로 강조.
/// 다음 차(`isImminent`)일 때만 숫자에 핀포인트 블루.
class _ArrivalTime extends StatelessWidget {
  final String minutes;
  final bool isImminent;

  const _ArrivalTime({required this.minutes, required this.isImminent});

  @override
  Widget build(BuildContext context) {
    final numberColor = isImminent ? _kPrimary : _kTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              minutes,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: numberColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 2),
            const Text(
              '분',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextMuted,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('후 도착', style: _kArrivalUnit),
      ],
    );
  }
}
