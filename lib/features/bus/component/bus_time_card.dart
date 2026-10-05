import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_button.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';

/// 홈 셔틀버스 카드 (Figma 2153:253).
///
/// 방향 띠 · 다음 출발 · 정류장 · 이후 출발 3편을 보여준다. 시각 계산은 버스
/// 상세 화면과 같은 [nextShuttleProvider] · [upcomingShuttlesProvider]를 써서
/// 두 화면의 표시가 항상 일치한다.
class Bustimescreen extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  const Bustimescreen({this.onTap, super.key});

  @override
  ConsumerState<Bustimescreen> createState() => _BustimescreenState();
}

class _BustimescreenState extends ConsumerState<Bustimescreen> {
  bool _isReverse = false; // false: 학교→정왕역 / true: 정왕역→학교

  @override
  Widget build(BuildContext context) {
    final from = _isReverse ? '정왕역' : '학교';
    final to = _isReverse ? '학교' : '정왕역';
    final stopName = _isReverse ? '정왕역 버스 정류장' : '정문 버스 정류장';

    // 상세 화면과 동일한 방향 매핑 → 동일한 다음 셔틀 결과.
    final direction =
        _isReverse
            ? ShuttleDirection.jeongwangToSchool
            : ShuttleDirection.schoolToJeongwang;
    const route = ShuttleRoute.route1;
    final now = ref.watch(shuttleClockProvider);
    final next = ref.watch(
      nextShuttleProvider(route: route, direction: direction),
    );
    final departures = ref.watch(
      upcomingShuttlesProvider(route: route, direction: direction),
    );

    return SandolCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DirectionBar(
            from: from,
            to: to,
            onSwap: () => setState(() => _isReverse = !_isReverse),
            onRefresh: () => ref.read(shuttleClockProvider.notifier).refresh(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SandolMetrics.cardInset,
              vertical: 10,
            ),
            child: SandolIconLabel(
              icon: SvgPicture.asset(SandolAssets.clock),
              label: next.headline,
              style: SandolTypography.title.accent,
            ),
          ),
          const Divider(height: 1, thickness: 1, color: SandolColors.muted),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SandolMetrics.cardInset,
              13,
              SandolMetrics.cardInset,
              SandolSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SandolIconLabel(
                  icon: SvgPicture.asset(SandolAssets.busStop),
                  label: stopName,
                  style: SandolTypography.headline.strong,
                  gap: 9,
                ),
                const SizedBox(height: 29),
                if (departures.isEmpty)
                  Text(
                    next.subText ?? '운행 정보가 없어요',
                    style: SandolTypography.body.muted,
                  )
                else
                  Column(
                    spacing: 12,
                    children: [
                      for (final entry in departures)
                        _DepartureRow(
                          entry: entry,
                          nowMinutes: now.hour * 60 + now.minute,
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                Center(
                  child: SandolIconLabel.note('도착 시간은 교통 상황에 따라 달라질 수 있어요.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// primary 띠: `학교 → 정왕역` + 방향 전환 · 새로고침 버튼
class _DirectionBar extends StatelessWidget {
  const _DirectionBar({
    required this.from,
    required this.to,
    required this.onSwap,
    required this.onRefresh,
  });

  final String from;
  final String to;
  final VoidCallback onSwap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = SandolTypography.caption.onPrimary;
    return ColoredBox(
      color: SandolColors.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SandolMetrics.cardInset,
          vertical: SandolSpacing.xs,
        ),
        child: Row(
          children: [
            Row(
              spacing: 6,
              children: [
                Text(from, style: label),
                RotatedBox(
                  quarterTurns: 2,
                  child: SvgPicture.asset(SandolAssets.arrowLeft),
                ),
                Text(to, style: label),
              ],
            ),
            const Spacer(),
            Row(
              spacing: SandolSpacing.sm,
              children: [
                SandolIconButton(
                  tooltip: '반대 방향',
                  icon: SvgPicture.asset(SandolAssets.swap),
                  onTap: onSwap,
                ),
                SandolIconButton(
                  tooltip: '새로고침',
                  icon: SvgPicture.asset(SandolAssets.refresh),
                  onTap: onRefresh,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 이후 출발 한 줄. 정시편은 `9:00시 · N분`, 구간은 `17:00~18:00 · 수시운행`.
class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.entry, required this.nowMinutes});

  final ShuttleEntry entry;
  final int nowMinutes;

  static String _clock(ShuttleTime t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  static String _remain(int minutes) {
    if (minutes < 60) return '$minutes분';
    final m = minutes % 60;
    return m == 0 ? '${minutes ~/ 60}시간' : '${minutes ~/ 60}시간 $m분';
  }

  @override
  Widget build(BuildContext context) {
    final end = entry.endTime;
    final (time, trailing) =
        entry.isSegment && end != null
            ? (
              '${_clock(entry.time)}~${_clock(end)}',
              NextShuttleCalculator.segmentName(entry),
            )
            : (
              '${_clock(entry.time)}시',
              _remain(entry.time.minutesOfDay - nowMinutes),
            );

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SandolIconLabel(
              icon: SvgPicture.asset(SandolAssets.busDeparture),
              label: time,
              style: SandolTypography.body,
              gap: SandolSpacing.xs,
            ),
          ),
        ),
        Text(trailing, style: SandolTypography.body),
      ],
    );
  }
}
