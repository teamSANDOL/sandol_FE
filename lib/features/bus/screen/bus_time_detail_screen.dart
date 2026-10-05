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
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';

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
  /// 노선1(정왕역 ↔ 본교)만 다룬다. 기본은 하교 방향.
  static const _route = ShuttleRoute.route1;
  ShuttleDirection _direction = ShuttleDirection.schoolToJeongwang;

  void _swap() => setState(() => _direction = _direction.reversed);

  /// 당겨서 새로고침 · 카드 버튼. 기준 시각을 갱신하면 다음 버스 · 시간표 ·
  /// 마지막 업데이트가 함께 다시 계산된다.
  Future<void> _refresh() async {
    ref.read(shuttleClockProvider.notifier).refresh();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(shuttleClockProvider);
    final next = ref.watch(
      nextShuttleProvider(route: _route, direction: _direction),
    );
    final timetable = ShuttleScheduleData.timetableFor(
      route: _route,
      direction: _direction,
      dayType: ShuttleScheduleData.dayTypeOf(now),
    );

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
                  direction: _direction,
                  onSwap: _swap,
                  onSelect: (d) => setState(() => _direction = d),
                ),
                const SizedBox(height: SandolSpacing.xl),
                _NextBusCard(next: next, onRefresh: _refresh),
                const SizedBox(height: 48),
                _TimetableHeader(direction: _direction),
                const SizedBox(height: 12),
                _TimetableCard(
                  timetable: timetable,
                  nowMinutes: now.hour * 60 + now.minute,
                ),
                const SizedBox(height: SandolSpacing.lg),
                _FooterNote(lastUpdated: now),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 노선1 정류장 ──────────────────────────────────────────────────────────────

extension on ShuttleDirection {
  ShuttleDirection get reversed => switch (this) {
    ShuttleDirection.schoolToJeongwang => ShuttleDirection.jeongwangToSchool,
    ShuttleDirection.jeongwangToSchool => ShuttleDirection.schoolToJeongwang,
    _ => this,
  };

  String get origin => switch (this) {
    ShuttleDirection.jeongwangToSchool => _Stop.station,
    _ => _Stop.school,
  };

  String get destination => reversed.origin;
}

abstract final class _Stop {
  static const school = '한국공학대 정문';
  static const station = '정왕역';
}

// ── 출발 · 도착 카드 (2158:1281) ─────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.direction,
    required this.onSwap,
    required this.onSelect,
  });

  final ShuttleDirection direction;
  final VoidCallback onSwap;
  final ValueChanged<ShuttleDirection> onSelect;

  /// 카드 윗변에서 가운데 구분선까지. 교환 버튼이 이 선 위에 걸친다.
  static const double _lineTop = 72;
  static const Size _swapSize = Size(35.06, 36.58);

  /// 출발지(또는 도착지)를 골라 방향을 정한다. 정왕역 노선은 정류장이 둘뿐이라
  /// 한쪽을 고르면 반대쪽은 자동으로 정해진다.
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
            selected: origin ? direction.origin : direction.destination,
          ),
    );
    if (picked == null) return;
    final toStation = origin ? picked == _Stop.school : picked == _Stop.station;
    onSelect(
      toStation
          ? ShuttleDirection.schoolToJeongwang
          : ShuttleDirection.jeongwangToSchool,
    );
  }

  @override
  Widget build(BuildContext context) => SandolCard(
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 20, 16),
              child: _StopRow(
                icon: SandolAssets.busStopPin,
                label: '출발',
                name: direction.origin,
                gap: SandolSpacing.sm,
                button: SandolAssets.busPinButton,
                onTap: () => _pickStop(context, origin: true),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: SandolColors.field),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 20, 24),
              child: _StopRow(
                icon: SandolAssets.busStopFlag,
                label: '도착',
                name: direction.destination,
                gap: SandolSpacing.xs,
                button: SandolAssets.busChevronButton,
                onTap: () => _pickStop(context, origin: false),
              ),
            ),
          ],
        ),
        Positioned(
          top: _lineTop - _swapSize.height / 2,
          left: 0,
          right: 0,
          child: Center(
            child: SandolIconButton(
              tooltip: '출발 · 도착 바꾸기',
              onTap: onSwap,
              icon: SvgPicture.asset(SandolAssets.busSwap),
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
    required this.gap,
    required this.button,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String name;
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
  const _StopPickerSheet({required this.title, required this.selected});

  final String title;
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
          for (final stop in const [_Stop.school, _Stop.station])
            InkWell(
              borderRadius: SandolMetrics.radius,
              onTap: () => Navigator.pop(context, stop),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  stop,
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
            height: 47,
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

// ── 전체 시간표 (2156:511 · 2156:514) ────────────────────────────────────────

class _TimetableHeader extends StatelessWidget {
  const _TimetableHeader({required this.direction});

  final ShuttleDirection direction;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: Row(
      children: [
        const Text('전체 시간표', style: SandolTypography.title),
        const Spacer(),
        Text(
          '${direction.origin} → ${direction.destination}',
          style: SandolTypography.body.muted,
        ),
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
        SizedBox(
          width: 64,
          child: Text('${hour.toString().padLeft(2, '0')}시', style: hourStyle),
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
  const _FooterNote({required this.lastUpdated});

  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final hh = lastUpdated.hour.toString().padLeft(2, '0');
    final mm = lastUpdated.minute.toString().padLeft(2, '0');
    return Text(
      '시간표는 학교 사정에 따라 변경될 수 있어요.\n마지막 업데이트 • 오늘 $hh:$mm',
      textAlign: TextAlign.center,
      style: SandolTypography.caption.inactive,
    );
  }
}
