import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_button.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';
import 'package:handori/features/bus/domain/usecase/shuttle_transfer.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/bus/presentation/provider/shuttle_direction_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';

/// 셔틀버스 탭 (Figma 2156:451).
///
/// 출발·도착 카드, 다음 버스 카드, 오늘 전체 시간표를 한 화면에 둔다.
/// 다음 버스·지나간 시각 판정은 홈 카드와 같은 [shuttleClockProvider] ·
/// [nextShuttleProvider]를 써서 두 화면이 항상 같은 출발을 가리킨다.
class BusTimeDetailScreen extends ConsumerStatefulWidget {
  const BusTimeDetailScreen({super.key});

  @override
  ConsumerState<BusTimeDetailScreen> createState() =>
      _BusTimeDetailScreenState();
}

class _BusTimeDetailScreenState extends ConsumerState<BusTimeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _retryLocation());
  }

  /// 사용자가 직접 연 화면이므로 위치를 스스로 얻는다. 이전에 위치를 못 얻었으면
  /// (권한 미결정 포함) 다시 시도하고, 영구 거부 · 위치 꺼짐이면 묻지 않는다.
  Future<void> _retryLocation() async {
    final location = ref.read(userLocationProvider);
    if (location.hasValue &&
        location.value == null &&
        await canRetryLocation()) {
      if (mounted) ref.invalidate(userLocationProvider);
    }
  }

  void _select(ShuttleDirection d) =>
      ref.read(shuttleDirectionSelectionProvider.notifier).select(d);

  /// 당겨서 새로고침 · 카드 버튼. 기준 시각을 갱신하면 다음 버스 · 시간표 ·
  /// 마지막 업데이트가 함께 다시 계산된다.
  Future<void> _refresh() async {
    ref.read(shuttleClockProvider.notifier).refresh();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    // 위치가 잡히면 방향 선택 provider가 가까운 출발지를 고른다.
    ref.watch(userLocationProvider);
    final direction = ref.watch(shuttleDirectionSelectionProvider);
    final now = ref.watch(shuttleClockProvider);
    final next = ref.watch(
      nextShuttleProvider(route: direction.route, direction: direction),
    );
    final timetable = ref.watch(
      shuttleTimetableProvider(route: direction.route, direction: direction),
    );
    final stops = ref.watch(shuttleStopsProvider);
    final transfers = ref.watch(shuttleTransfersProvider(direction: direction));
    final needsReview =
        ref.watch(shuttleScheduleSourceProvider)?.needsReview ?? false;

    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '셔틀버스',
        titleWidget: const Text('셔틀버스', style: SandolTypography.title),
        backIcon: SvgPicture.asset(SandolAssets.backArrow),
        onBack:
            () => StatefulNavigationShell.of(
              context,
            ).goBranch(RootShell.homeBranch),
        backgroundColor: SandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: SandolMetrics.pageGutter - 10,
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          RefreshIndicator(
            color: SandolColors.primary,
            backgroundColor: SandolColors.background,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.pageGutter,
                SandolSpacing.md,
                SandolMetrics.pageGutter,
                SandolSpacing.xl,
              ),
              children: [
                _RouteCard(
                  direction: direction,
                  stops: stops,
                  onSwap: () => _select(direction.reversed),
                  onSelect: _select,
                ),
                const SizedBox(height: SandolSpacing.xl),
                _NextBusCard(next: next, onRefresh: _refresh),
                if (transfers != null) ...[
                  const SizedBox(height: SandolSpacing.xl),
                  _TransferCard(
                    school: stops['main_campus']!.name,
                    connections: transfers,
                  ),
                ],
                const SizedBox(height: 48),
                _TimetableHeader(
                  route:
                      '${stops[direction.origin]!.name} → '
                      '${stops[direction.destination]!.name}'
                      '${direction.viaSchool ? ' (${stops['main_campus']!.name} 경유)' : ''}',
                ),
                const SizedBox(height: 12),
                _TimetableCard(
                  timetable: timetable,
                  nowMinutes: now.hour * 60 + now.minute,
                ),
                const SizedBox(height: SandolSpacing.lg),
                _FooterNote(lastUpdated: now, needsReview: needsReview),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 고를 수 있는 정류장(서버 정류장 id). 이름·안내는 [shuttleStopsProvider]에서 찾는다.
const _stopIds = ['main_campus', 'jeongwang', 'campus2'];

// ── 출발 · 도착 카드 (2158:1281) ─────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.direction,
    required this.stops,
    required this.onSwap,
    required this.onSelect,
  });

  final ShuttleDirection direction;
  final Map<String, ShuttleStop> stops;
  final VoidCallback onSwap;
  final ValueChanged<ShuttleDirection> onSelect;

  /// 가운데 구분선 줄의 높이. 교환 버튼이 이 줄 안에서 선 위에 걸친다.
  static const double _swapRowHeight = 36.58;

  /// 출발지(또는 도착지)를 골라 방향을 정한다. 반대쪽과 같은 정류장을 고르면
  /// 출발·도착을 맞바꿔 같은 정류장끼리의 조합은 생기지 않는다.
  Future<void> _pickStop(BuildContext context, {required bool origin}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SandolColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: SandolMetrics.radiusTop,
      ),
      builder:
          (_) => _StopPickerSheet(
            title: origin ? '출발 정류장' : '도착 정류장',
            stops: stops,
            selected: origin ? direction.origin : direction.destination,
          ),
    );
    if (picked == null) return;
    final next =
        origin
            ? ShuttleDirection.between(picked, direction.destination)
            : ShuttleDirection.between(direction.origin, picked);
    onSelect(next ?? direction.reversed);
  }

  @override
  Widget build(BuildContext context) => SandolCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 20, 0),
          child: _StopRow(
            icon: SandolAssets.busStopPin,
            label: '출발',
            name: stops[direction.origin]!.name,
            note: stops[direction.origin]!.boardingNote,
            gap: SandolSpacing.sm,
            button: SandolAssets.busPinButton,
            onTap: () => _pickStop(context, origin: true),
          ),
        ),
        // 버튼을 카드 위에 겹쳐 두면 글꼴이 커질 때 이름을 덮으므로
        // 구분선과 같은 줄에 두어 위아래 내용이 늘어나도 따라 내려가게 한다.
        SizedBox(
          height: _swapRowHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Divider(height: 1, thickness: 1, color: SandolColors.field),
              SandolIconButton(
                tooltip: '출발 · 도착 바꾸기',
                onTap: onSwap,
                icon: SvgPicture.asset(SandolAssets.busSwap),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 20, 24),
          child: _StopRow(
            icon: SandolAssets.busStopFlag,
            label: '도착',
            name: stops[direction.destination]!.name,
            note:
                direction.viaSchool ? '${stops['main_campus']!.name} 경유' : null,
            gap: SandolSpacing.xs,
            button: SandolAssets.busChevronButton,
            onTap: () => _pickStop(context, origin: false),
          ),
        ),
      ],
    ),
  );
}

/// `ⓟ 출발` 캡션 + 정류장 이름, 오른쪽 끝 원형 버튼
class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.icon,
    required this.label,
    required this.name,
    this.note,
    required this.gap,
    required this.button,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String name;

  /// 이름 아래 작은 안내. 출발은 승차 위치(서버 `boarding_note`), 도착은 경유지.
  final String? note;
  final double gap;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: SandolSpacing.xs,
              children: [
                SvgPicture.asset(icon),
                Text(label, style: SandolTypography.caption),
              ],
            ),
            SizedBox(height: gap),
            Text(
              name,
              style: SandolTypography.body.strong.copyWith(
                color: SandolColors.textSecondary,
              ),
            ),
            if (note case final String note)
              Text(note, style: SandolTypography.caption.inactive),
          ],
        ),
      ),
      SandolIconButton(
        tooltip: '$label 정류장 선택',
        onTap: onTap,
        icon: SvgPicture.asset(button),
      ),
    ],
  );
}

class _StopPickerSheet extends StatelessWidget {
  const _StopPickerSheet({
    required this.title,
    required this.stops,
    required this.selected,
  });

  final String title;
  final Map<String, ShuttleStop> stops;

  /// 선택된 정류장 id.
  final String selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.cardInset,
        SandolSpacing.md,
        SandolMetrics.cardInset,
        SandolSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: SandolTypography.title),
          const SizedBox(height: SandolSpacing.sm),
          for (final stop in _stopIds)
            InkWell(
              borderRadius: SandolMetrics.radius,
              onTap: () => Navigator.pop(context, stop),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  stops[stop]!.name,
                  style:
                      stop == selected
                          ? SandolTypography.body.strong.accent
                          : SandolTypography.body,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ── 다음 버스 카드 (2156:490) ────────────────────────────────────────────────

class _NextBusCard extends StatelessWidget {
  const _NextBusCard({required this.next, required this.onRefresh});

  final NextShuttle next;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final headline = SandolTypography.headline.strong;
    return SandolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 47),
            color: SandolColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Text('다음 버스', style: SandolTypography.body.strong.onPrimary),
                const Spacer(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: SandolColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 4),
                ),
                const SizedBox(width: SandolSpacing.xs),
                Text('실시간', style: SandolTypography.body.strong.onPrimary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SandolMetrics.cardInset,
              vertical: 12,
            ),
            child: Row(
              children: [
                SvgPicture.asset(SandolAssets.busNext),
                const SizedBox(width: SandolSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SandolSpacing.xs,
                    children: [
                      Text(
                        next.headline,
                        style:
                            next.isActive ? headline.accent : headline.inactive,
                      ),
                      if (next.subText case final String sub)
                        Text(
                          sub,
                          style: SandolTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: SandolSpacing.sm),
                SandolIconButton(
                  tooltip: '새로고침',
                  onTap: onRefresh,
                  icon: SvgPicture.asset(SandolAssets.busRefresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 본교 환승 (정왕역 ↔ 제2캠퍼스) ─────────────────────────────────────────

/// 직행편 말고 본교에서 갈아타는 연결. 간격이 안전 기준이라 '예상'으로 적는다.
/// "이전 버스도 보기"를 펼치면 같은 환승편에 빠듯하게 닿는 1구간 편도 보인다.
class _TransferCard extends StatefulWidget {
  const _TransferCard({required this.school, required this.connections});

  /// 본교 정류장 이름.
  final String school;
  final List<ShuttleConnection> connections;

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  bool _showTighter = false;

  static String _row(ShuttleTime departure, ShuttleTime transfer, String tag) =>
      '${departure.label} 출발$tag → 본교 ${transfer.label} 환승 출발'.keepAll;

  @override
  Widget build(BuildContext context) {
    final connections = widget.connections;
    final hasTighter = connections.any((c) => c.tighter.isNotEmpty);
    return SandolCard(
      child: Padding(
        padding: const EdgeInsets.all(SandolMetrics.cardInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SandolSpacing.sm,
          children: [
            Text(
              '${widget.school}에서 갈아타기 (예상)'.keepAll,
              style: SandolTypography.body.strong,
            ),
            if (connections.isEmpty)
              Text('오늘 환승 가능한 편이 없어요', style: SandolTypography.body.muted)
            else
              for (final c in connections) ...[
                Text(
                  _row(
                    c.departure,
                    c.transfer,
                    c.first.isSegment
                        ? ' (${NextShuttleCalculator.segmentName(c.first)})'
                        : '',
                  ),
                  style: SandolTypography.body,
                ),
                // 같은 환승편으로 이어지는, 더 늦게 출발하는 1구간 편.
                if (_showTighter)
                  for (final t in c.tighter)
                    Text(
                      _row(t, c.transfer, ' (빠듯함)'),
                      style: SandolTypography.body.muted,
                    ),
              ],
            if (hasTighter)
              TextButton(
                onPressed: () => setState(() => _showTighter = !_showTighter),
                child: Text(_showTighter ? '이전 버스 숨기기' : '이전 버스도 보기'),
              ),
            Text(
              '환승 시간은 교통 상황에 따라 달라질 수 있어요'.keepAll,
              style: SandolTypography.caption.inactive,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 전체 시간표 (2156:511 · 2156:514) ────────────────────────────────────────

class _TimetableHeader extends StatelessWidget {
  const _TimetableHeader({required this.route});

  /// `출발 → 도착` 정류장 이름.
  final String route;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 30),
    // 큰 글꼴에서 제목과 경로가 한 줄에 안 들어가면 경로가 아래 줄로 내려간다.
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: SandolSpacing.sm,
      children: [
        const Text('전체 시간표', style: SandolTypography.title),
        Text(route, style: SandolTypography.body.muted),
      ],
    ),
  );
}

/// 시(hour)별 한 줄에 출발 분을 `•00`로 나열한다. 지나간 시간대는 비활성 색,
/// 다음 출발이 든 시간대는 강조색. 수시운행 같은 구간은 표 아래 한 줄로 적는다.
class _TimetableCard extends StatelessWidget {
  const _TimetableCard({required this.timetable, required this.nowMinutes});

  final ShuttleTimetable? timetable;
  final int nowMinutes;

  @override
  Widget build(BuildContext context) {
    final entries = timetable?.entries ?? const <ShuttleEntry>[];
    final hours = <int, List<ShuttleTime>>{};
    final segments = <ShuttleEntry>[];
    for (final e in entries) {
      if (e.isSegment) {
        segments.add(e);
      } else {
        hours.putIfAbsent(e.time.hour, () => []).add(e.time);
      }
    }
    // 다음 정시 출발이 든 시간대만 강조한다. 다음 버스 카드와 같은 기준.
    final nextHour =
        entries
            .where((e) => !e.isSegment && e.time.minutesOfDay >= nowMinutes)
            .firstOrNull
            ?.time
            .hour;

    return SandolCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SandolMetrics.cardInset,
        vertical: SandolSpacing.md,
      ),
      child:
          entries.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: SandolSpacing.md),
                child: Text(
                  '오늘은 셔틀을 운행하지 않아요',
                  textAlign: TextAlign.center,
                  style: SandolTypography.body.inactive,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 32,
                children: [
                  for (final MapEntry(key: hour, value: times) in hours.entries)
                    _HourRow(
                      hour: hour,
                      times: times,
                      nowMinutes: nowMinutes,
                      highlighted: hour == nextHour,
                    ),
                  for (final segment in segments) _SegmentNote(segment),
                ],
              ),
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.hour,
    required this.times,
    required this.nowMinutes,
    required this.highlighted,
  });

  final int hour;
  final List<ShuttleTime> times;
  final int nowMinutes;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final past = times.last.minutesOfDay < nowMinutes;
    final hourStyle =
        past
            ? SandolTypography.headline.inactive
            : highlighted
            ? SandolTypography.headline.strong.accent
            : SandolTypography.headline.strong;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            '${hour.toString().padLeft(2, '0')}시',
            style: hourStyle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: SandolSpacing.sm,
            children: [
              for (final t in times)
                Text(
                  '•${t.minute.toString().padLeft(2, '0')}',
                  style:
                      t.minutesOfDay < nowMinutes
                          ? SandolTypography.body.inactive
                          : SandolTypography.body,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `17:00 ~ 18:00 •수시 운행` — 정시 출발이 없는 구간 안내
class _SegmentNote extends StatelessWidget {
  const _SegmentNote(this.segment);

  final ShuttleEntry segment;

  @override
  Widget build(BuildContext context) {
    final end = segment.endTime;
    final range =
        end == null
            ? '${segment.time.label} 이후'
            : '${segment.time.label} ~ ${end.label}';
    final name =
        segment.type == ShuttleEntryType.flexible ? '수시 운행' : '도착버스 탑승';
    return Column(
      spacing: SandolSpacing.xs,
      children: [
        Text(
          '$range •$name',
          textAlign: TextAlign.center,
          style: SandolTypography.body.inactive,
        ),
        if (segment.boardingNote case final String note)
          Text(
            note,
            textAlign: TextAlign.center,
            style: SandolTypography.caption.inactive,
          ),
      ],
    );
  }
}

// ── 안내 (2156:625) ──────────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.lastUpdated, required this.needsReview});

  final DateTime lastUpdated;

  /// 서버가 최신 시간표 검증에 실패해 직전 정상본을 주는 중인지.
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final hh = lastUpdated.hour.toString().padLeft(2, '0');
    final mm = lastUpdated.minute.toString().padLeft(2, '0');
    final review = needsReview ? '\n최신 시간표를 확인 중이라 실제와 다를 수 있어요.' : '';
    return Text(
      '시간표는 학교 사정에 따라 변경될 수 있어요.$review\n마지막 업데이트 • 오늘 $hh:$mm',
      textAlign: TextAlign.center,
      style: SandolTypography.caption.inactive,
    );
  }
}
