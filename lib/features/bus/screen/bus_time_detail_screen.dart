import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handol/common/component/app_top_bar.dart';
import 'package:handol/common/component/handol_scroll_gradient.dart';
import 'package:handol/common/component/handol_card.dart';
import 'package:handol/common/component/handol_icon_button.dart';
import 'package:handol/common/layout/root_shell.dart';
import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/core/utils/keep_all.dart';
import 'package:handol/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handol/features/bus/domain/usecase/next_shuttle_calculator.dart';
import 'package:handol/features/bus/domain/usecase/shuttle_transfer.dart';
import 'package:handol/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handol/features/bus/presentation/provider/shuttle_direction_provider.dart';
import 'package:handol/features/empty_class/presentation/provider/user_location_provider.dart';

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
  /// 배경 그라데이션을 스크롤 내용과 함께 움직이기 위해 쓴다.
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
      backgroundColor: HandolColors.background,
      appBar: AppTopBar(
        title: '셔틀버스',
        titleWidget: const Text('셔틀버스', style: HandolTypography.title),
        backIcon: SvgPicture.asset(HandolAssets.backArrow),
        onBack:
            () => StatefulNavigationShell.of(
              context,
            ).goBranch(RootShell.homeBranch),
        backgroundColor: HandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: HandolMetrics.pageGutter - 10,
      ),
      // 시안 2156:451 은 프레임이 스크롤 전체(1304)라 배경도 내용 전체에 번진다.
      body: HandolScrollGradient(
        controller: _scroll,
        child: RefreshIndicator(
          color: HandolColors.primary,
          backgroundColor: HandolColors.background,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HandolMetrics.pageGutter,
                  HandolSpacing.md,
                  HandolMetrics.pageGutter,
                  40,
                ),
                sliver: SliverList.list(
                  children: [
                    _RouteCard(
                      direction: direction,
                      stops: stops,
                      onSwap: () => _select(direction.reversed),
                      onSelect: _select,
                    ),
                    const SizedBox(height: HandolSpacing.xl),
                    _NextBusCard(next: next, onRefresh: _refresh),
                    if (transfers != null) ...[
                      const SizedBox(height: HandolSpacing.xl),
                      _TransferCard(
                        school: stops['main_campus']!.name,
                        connections: transfers,
                      ),
                    ],
                  ],
                ),
              ),
              // 시간표를 내려 읽는 동안 어느 방면인지 위에 붙여 둔다.
              // 헤더 뒤에는 그 자리의 배경 그라데이션을 그대로 깔아, 아래로
              // 지나가는 표는 가리고 배경과는 이음매 없이 맞춘다.
              SliverLayoutBuilder(
                builder:
                    (context, c) => PinnedHeaderSliver(
                      child: HandolGradientSlice(
                        top: c.precedingScrollExtent + c.scrollOffset,
                        extent:
                            HandolScrollGradient.extentOf(_scroll) ??
                            MediaQuery.sizeOf(context).height,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            HandolMetrics.pageGutter,
                            HandolSpacing.sm,
                            HandolMetrics.pageGutter,
                            12,
                          ),
                          child: _TimetableHeader(
                            route:
                                '${stops[direction.origin]!.name} → '
                                '${stops[direction.destination]!.name}'
                                '${direction.viaSchool ? ' (${stops['main_campus']!.name} 경유)' : ''}',
                          ),
                        ),
                      ),
                    ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HandolMetrics.pageGutter,
                  0,
                  HandolMetrics.pageGutter,
                  HandolSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: _TimetableCard(
                    // 방면이 바뀌면 지난 시간 펼침도 처음(접힘)으로.
                    key: ValueKey(direction),
                    timetable: timetable,
                    nowMinutes: now.hour * 60 + now.minute,
                    footer: _FooterNote(
                      lastUpdated: now,
                      needsReview: needsReview,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      backgroundColor: HandolColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: HandolMetrics.radiusTop,
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
  Widget build(BuildContext context) => HandolCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 아이콘 버튼뿐 아니라 이름 · 카드 영역을 눌러도 정류장을 고른다.
        InkWell(
          onTap: () => _pickStop(context, origin: true),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 20, 0),
            child: _StopRow(
              icon: HandolAssets.busStopPin,
              label: '출발',
              name: stops[direction.origin]!.name,
              note: stops[direction.origin]!.boardingNote,
              gap: HandolSpacing.sm,
              button: HandolAssets.busPinButton,
              onTap: () => _pickStop(context, origin: true),
            ),
          ),
        ),
        // 버튼을 카드 위에 겹쳐 두면 글꼴이 커질 때 이름을 덮으므로
        // 구분선과 같은 줄에 두어 위아래 내용이 늘어나도 따라 내려가게 한다.
        SizedBox(
          height: _swapRowHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Divider(height: 1, thickness: 1, color: HandolColors.field),
              HandolIconButton(
                tooltip: '출발 · 도착 바꾸기',
                onTap: onSwap,
                icon: SvgPicture.asset(HandolAssets.busSwap),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _pickStop(context, origin: false),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 20, 24),
            child: _StopRow(
              icon: HandolAssets.busStopFlag,
              label: '도착',
              name: stops[direction.destination]!.name,
              note:
                  direction.viaSchool
                      ? '${stops['main_campus']!.name} 경유'
                      : null,
              gap: HandolSpacing.xs,
              button: HandolAssets.busChevronButton,
              onTap: () => _pickStop(context, origin: false),
            ),
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
              spacing: HandolSpacing.xs,
              children: [
                SvgPicture.asset(icon),
                Text(label, style: HandolTypography.caption),
              ],
            ),
            SizedBox(height: gap),
            Text(
              name,
              style: HandolTypography.body.strong.copyWith(
                color: HandolColors.textSecondary,
              ),
            ),
            if (note case final String note)
              Text(note, style: HandolTypography.caption.inactive),
          ],
        ),
      ),
      HandolIconButton(
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
        HandolMetrics.cardInset,
        HandolSpacing.md,
        HandolMetrics.cardInset,
        HandolSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: HandolTypography.title),
          const SizedBox(height: HandolSpacing.sm),
          for (final stop in _stopIds)
            InkWell(
              borderRadius: HandolMetrics.radius,
              onTap: () => Navigator.pop(context, stop),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  stops[stop]!.name,
                  style:
                      stop == selected
                          ? HandolTypography.body.strong.accent
                          : HandolTypography.body,
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
    final headline = HandolTypography.headline.strong;
    return HandolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 47),
            color: HandolColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Text('다음 버스', style: HandolTypography.body.strong.onPrimary),
                const Spacer(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: HandolColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 4),
                ),
                const SizedBox(width: HandolSpacing.xs),
                Text('실시간', style: HandolTypography.body.strong.onPrimary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HandolMetrics.cardInset,
              vertical: 12,
            ),
            child: Row(
              children: [
                SvgPicture.asset(HandolAssets.busNext),
                const SizedBox(width: HandolSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: HandolSpacing.xs,
                    children: [
                      Text(
                        next.headline,
                        style:
                            next.isActive ? headline.accent : headline.inactive,
                      ),
                      if (next.subText case final String sub)
                        Text(
                          sub,
                          style: HandolTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: HandolSpacing.sm),
                HandolIconButton(
                  tooltip: '새로고침',
                  onTap: onRefresh,
                  icon: SvgPicture.asset(HandolAssets.busRefresh),
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
    final hasTighter = connections.any((c) => c.tight);
    // 기본은 안전 연결만, 펼치면 빠듯한 연결까지 출발 시각순으로.
    final shown = [
      for (final c in connections)
        if (_showTighter || !c.tight) c,
    ];
    return HandolCard(
      child: Padding(
        padding: const EdgeInsets.all(HandolMetrics.cardInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: HandolSpacing.sm,
          children: [
            Text(
              '${widget.school}에서 갈아타기 (예상)'.keepAll,
              style: HandolTypography.body.strong,
            ),
            if (connections.every((c) => c.tight))
              Text('오늘 환승 가능한 편이 없어요', style: HandolTypography.body.muted),
            for (final c in shown)
              Text(
                _row(
                  c.departure,
                  c.transfer,
                  c.tight
                      ? ' (빠듯함)'
                      : c.first.isSegment
                      ? ' (${NextShuttleCalculator.segmentName(c.first)})'
                      : '',
                ),
                style:
                    c.tight
                        ? HandolTypography.body.muted
                        : HandolTypography.body,
              ),
            if (hasTighter)
              TextButton(
                onPressed: () => setState(() => _showTighter = !_showTighter),
                child: Text(_showTighter ? '이전 버스 숨기기' : '이전 버스도 보기'),
              ),
            Text(
              '환승 시간은 교통 상황에 따라 달라질 수 있어요'.keepAll,
              style: HandolTypography.caption.inactive,
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
      spacing: HandolSpacing.sm,
      children: [
        const Text('전체 시간표', style: HandolTypography.title),
        Text(route, style: HandolTypography.body.muted),
      ],
    ),
  );
}

/// 출발 한 편(또는 수시운행 같은 구간)마다 한 줄 (Figma 2683:3145).
/// 다음 출발 · 수시 운행 · 막차는 배지로, 오른쪽엔 남은 시간을 적는다.
/// 다 지나간 줄은 맨 위 '지난 시간 보기' 한 줄로 접어 두어 지금 시각이
/// 표의 첫 줄이 되게 한다. 안내 문구는 카드 맨 아래에 둔다.
class _TimetableCard extends StatefulWidget {
  const _TimetableCard({
    super.key,
    required this.timetable,
    required this.nowMinutes,
    required this.footer,
  });

  final ShuttleTimetable? timetable;
  final int nowMinutes;
  final Widget footer;

  @override
  State<_TimetableCard> createState() => _TimetableCardState();
}

class _TimetableCardState extends State<_TimetableCard> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final now = widget.nowMinutes;
    final entries = widget.timetable?.entries ?? const <ShuttleEntry>[];
    // 다음 버스 카드와 같은 기준: 지금 이후 첫 정시편.
    final next =
        entries
            .where((e) => !e.isSegment && e.time.minutesOfDay >= now)
            .firstOrNull;
    // 정시편으로 하루가 끝날 때만 막차. 뒤에 수시운행이 이어지면 막차가 아니다.
    final last = entries.lastOrNull;

    bool isPast(ShuttleEntry e) =>
        e.isSegment
            ? e.endTime != null && e.endTime!.minutesOfDay <= now
            : e.time.minutesOfDay < now;
    Widget row(ShuttleEntry e) => _EntryRow(
      entry: e,
      nowMinutes: now,
      past: isPast(e),
      isNext: identical(e, next),
      isLast: !e.isSegment && identical(e, last),
    );

    final past = [
      for (final e in entries)
        if (isPast(e)) e,
    ];
    final upcoming = [
      for (final e in entries)
        if (!isPast(e)) e,
    ];
    String hh(ShuttleEntry e) => e.time.hour.toString().padLeft(2, '0');
    final pastLabel = switch (past) {
      [] => '',
      [final only] => '${hh(only)}시',
      [final first, ..., final last] when hh(first) == hh(last) =>
        '${hh(first)}시',
      [final first, ..., final last] => '${hh(first)}~${hh(last)}시',
    };

    final rows = <Widget>[
      if (past.isNotEmpty)
        _PastToggle(
          expanded: _showPast,
          label: pastLabel,
          onTap: () => setState(() => _showPast = !_showPast),
        ),
      if (_showPast) ...[for (final e in past) row(e)],
      ...[for (final e in upcoming) row(e)],
    ];

    return HandolCard(
      padding: const EdgeInsets.only(top: 22, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entries.isEmpty)
            const _CenteredNote('오늘은 셔틀을 운행하지 않아요')
          else ...[
            for (final (i, r) in rows.indexed) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: HandolColors.border,
                ),
              r,
            ],
            if (upcoming.isEmpty) const _CenteredNote('오늘 남은 셔틀이 없어요'),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HandolMetrics.cardInset,
            ),
            child: widget.footer,
          ),
        ],
      ),
    );
  }
}

/// 시간표 줄의 안쪽 여백 (시안: 왼쪽 17, 오른쪽 23)
const _rowPadding = EdgeInsets.fromLTRB(17, 6, 23, 5);

class _CenteredNote extends StatelessWidget {
  const _CenteredNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HandolSpacing.md),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: HandolTypography.body.inactive,
    ),
  );
}

/// `🚌 14:35   [다음 출발]   약 8분 후`
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.nowMinutes,
    required this.past,
    required this.isNext,
    required this.isLast,
  });

  final ShuttleEntry entry;
  final int nowMinutes;
  final bool past;
  final bool isNext;
  final bool isLast;

  /// `약 8분 후` · `약 1시간 5분 후`
  static String eta(int minutes) {
    if (minutes <= 0) return '곧 출발';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '약 $m분 후';
    return m == 0 ? '약 $h시간 후' : '약 $h시간 $m분 후';
  }

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final end = e.endTime;
    final time = switch ((e.isSegment, end)) {
      (false, _) => e.time.label,
      (true, null) => '${e.time.label} 이후',
      (true, final ShuttleTime end) => '${e.time.label} ~ ${end.label}',
    };
    final start = e.time.minutesOfDay;
    final running = e.isSegment && start <= nowMinutes;
    final remaining =
        past
            ? null
            : running
            ? '운행 중'
            : eta(start - nowMinutes);
    final color =
        past
            ? HandolColors.inactive
            : isNext
            ? HandolColors.primary
            : HandolColors.textSecondary;
    final badge = switch (e.type) {
      ShuttleEntryType.flexible => ('수시 운행', HandolColors.orange),
      ShuttleEntryType.arrivalBoarding => ('도착버스 탑승', HandolColors.orange),
      _ when isLast => ('막차', isNext ? HandolColors.primary : color),
      _ when isNext => ('다음 출발', HandolColors.primary),
      _ => null,
    };
    final caption = HandolTypography.caption;

    return Padding(
      padding: _rowPadding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Row(
          spacing: HandolSpacing.sm,
          children: [
            // 시안의 시각 : 남은 시간 칸 비율(154 : 86)에 맞춘 3 : 2.
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: HandolSpacing.xs,
                    children: [
                      SvgPicture.asset(
                        HandolAssets.busRow,
                        width: HandolMetrics.iconSize,
                        height: HandolMetrics.iconSize,
                        theme: SvgTheme(currentColor: color),
                      ),
                      // 큰 글꼴에서도 시각은 한 줄. 칸이 모자라면 줄인다.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            time,
                            style: HandolTypography.body.strong.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (e.boardingNote case final String note)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(note, style: caption.inactive),
                    ),
                ],
              ),
            ),
            // 배지는 줄마다 같은 칸에 오도록 시각 · 남은 시간 사이에 고정 칸을 둔다.
            if (badge case (final String label, final Color bg))
              _Badge(label: label, color: past ? HandolColors.inactive : bg)
            else
              const SizedBox(width: _Badge.minWidth),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    remaining ?? '',
                    style: isNext ? caption.accent : caption.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 둥근 상태 배지 (시안 65×24, 모서리 30)
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  static const minWidth = 65.0;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: minWidth, minHeight: 24),
    padding: const EdgeInsets.symmetric(horizontal: HandolSpacing.sm),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(label, style: HandolTypography.caption.onPrimary),
  );
}

/// 접어 둔 지난 시간을 펼치고 접는 한 줄
class _PastToggle extends StatelessWidget {
  const _PastToggle({
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  final bool expanded;

  /// `09~13시`
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: _rowPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: HandolSpacing.xs,
        children: [
          Flexible(
            child: Text(
              expanded ? '지난 시간 접기' : '지난 시간 보기 · $label',
              style: HandolTypography.body.inactive,
            ),
          ),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: HandolTypography.body.inactive.color,
          ),
        ],
      ),
    ),
  );
}

// ── 안내 (2683:2995) ─────────────────────────────────────────────────────────

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
      style: HandolTypography.caption.inactive,
    );
  }
}
