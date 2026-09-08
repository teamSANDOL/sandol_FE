import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/constants/app_colors.dart';

import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/refresh_icon_button.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';

// ─── Color tokens ──────────────────────────────────────────────────────────
const Color _kPrimary = AppColors.primary;
const Color _kBgBase = AppColors.surface;
const Color _kBgSoft = AppColors.background;
const Color _kTextPrimary = AppColors.textPrimary;
const Color _kTextMuted = AppColors.textMuted;

/// 시안 고정값 — 카드 테두리(#E5E5EC). 앱 토큰(cardBorder)보다 중립 회색이라
/// 시안 그대로 유지한다.
const Color _kBorder = Color(0xFFE5E5EC);

/// 시안 고정값 — 다음 버스 헤더·시간 칩의 옅은 파랑.
const Color _kPrimaryTint = Color(0xFFE1F2FB);

/// 시안 고정값 — 운행 종료 타이틀·스왑 아이콘의 진회색.
const Color _kTextStrong = Color(0xFF505050);

// ─── Layout tokens ─────────────────────────────────────────────────────────
const double _kCardRadius = 16.0;

/// 시안에서 추출한 단색 스트로크 SVG 아이콘. [color]로 전체를 틴트한다.
class _SvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color color;

  const _SvgIcon(this.asset, {required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/bus/$asset',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class BusTimeDetailScreen extends ConsumerStatefulWidget {
  const BusTimeDetailScreen({super.key});

  @override
  ConsumerState<BusTimeDetailScreen> createState() =>
      _BusTimeDetailScreenState();
}

class _BusTimeDetailScreenState extends ConsumerState<BusTimeDetailScreen> {
  int _selectedDestination = 0; // 0: 정왕역 방면, 1: 학교 방면

  // 출발·도착 스왑 — 기존 방면 토글을 스왑 버튼 하나로 대체했다.
  void _onSwapPressed() {
    setState(() => _selectedDestination = 1 - _selectedDestination);
  }

  // 새로고침(당겨서 / 다음 버스 카드 버튼) — 기준 시각을 갱신하면
  // 다음 버스·시간표·마지막 업데이트 표시가 함께 다시 계산된다.
  Future<void> _onRefresh() async {
    ref.read(shuttleClockProvider.notifier).refresh();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final isToStation = _selectedDestination == 0;

    // 방면별 라벨 / 데이터.
    final originLabel = isToStation ? '한국공학대 정문' : '정왕역';
    final destinationLabel = isToStation ? '정왕역' : '한국공학대 정문';

    // 화면 스왑 → 노선1(정왕역↔본교) 방향 매핑.
    final direction = isToStation
        ? ShuttleDirection.schoolToJeongwang
        : ShuttleDirection.jeongwangToSchool;
    final nextShuttle = ref.watch(
      nextShuttleProvider(
        route: ShuttleRoute.route1,
        direction: direction,
      ),
    );

    // 마지막 새로고침 시각 — 시간표의 "지나간 시각" 판정·푸터 표시에 사용.
    final now = ref.watch(shuttleClockProvider);
    final timetable = ShuttleScheduleData.timetableFor(
      route: ShuttleRoute.route1,
      direction: direction,
      dayType: ShuttleScheduleData.dayTypeOf(now),
    );

    return Scaffold(
      backgroundColor: _kBgSoft,
      appBar: const AppTopBar(title: '버스조회'),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: _kPrimary,
          backgroundColor: _kBgBase,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 64),
            children: [
              _RouteCard(
                origin: originLabel,
                destination: destinationLabel,
                onSwap: _onSwapPressed,
              ),
              const SizedBox(height: 16),
              _NextBusCard(next: nextShuttle, onRefresh: _onRefresh),
              const SizedBox(height: 24),
              _TimetableSectionHeader(
                routeLabel: '$originLabel → $destinationLabel',
              ),
              const SizedBox(height: 10),
              _TimetableCard(
                timetable: timetable,
                nowMinutes: now.hour * 60 + now.minute,
              ),
              const SizedBox(height: 20),
              _FooterNote(lastUpdated: now),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Route card — 출발/도착 + 스왑 버튼
// ───────────────────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final String origin;
  final String destination;
  final VoidCallback onSwap;

  const _RouteCard({
    required this.origin,
    required this.destination,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _endpoint(
                  icon: 'ic_pin.svg',
                  iconColor: _kPrimary,
                  label: '출발',
                  value: origin,
                ),
                // 출발·도착 사이 점선 — 핀 아이콘 중심(왼쪽 9px)에 맞춘다.
                const Padding(
                  padding: EdgeInsets.only(left: 8.5, top: 6, bottom: 6),
                  child: CustomPaint(
                    size: Size(1, 16),
                    painter: _DashedLinePainter(_kBorder),
                  ),
                ),
                _endpoint(
                  icon: 'ic_flag.svg',
                  iconColor: _kTextMuted,
                  label: '도착',
                  value: destination,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SwapButton(onTap: onSwap),
        ],
      ),
    );
  }

  Widget _endpoint({
    required String icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        _SvgIcon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption04.copyWith(color: _kTextMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption01.copyWith(
                  color: _kTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SwapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBgBase,
      shape: const CircleBorder(side: BorderSide(color: _kBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _SvgIcon('ic_swap.svg', size: 20, color: _kTextStrong),
          ),
        ),
      ),
    );
  }
}

/// 출발·도착 사이 세로 점선.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    double y = 0;
    while (y < size.height) {
      final end = (y + dash) > size.height ? size.height : (y + dash);
      canvas.drawLine(Offset(0, y), Offset(0, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ───────────────────────────────────────────────────────────────────────────
// Next bus card — 다음 버스 상태
// ───────────────────────────────────────────────────────────────────────────

class _NextBusCard extends StatelessWidget {
  final NextShuttle next;

  /// 카드 우측 새로고침 버튼 — 도착 정보를 다시 불러온다.
  final Future<void> Function() onRefresh;

  const _NextBusCard({required this.next, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final remain = next.remainMinutes;

    // 상태 → 타이틀/보조 문구. 활성 상태만 파란 강조를 준다.
    String title;
    String? sub;
    var active = true;
    if (next.showsMinutes && remain != null && remain > 0) {
      title = '$remain분 후 출발';
      sub = next.subText;
    } else if (next.showsMinutes) {
      title = '곧 출발';
      sub = next.subText;
    } else if (next.isBeyondCountdown) {
      title = '${next.departureTime!.label} 출발';
      sub = '다음 버스 출발 시각이에요';
    } else if (next.status == ShuttleStatus.flexible ||
        next.status == ShuttleStatus.arrivalBoarding) {
      title = next.statusLabel ?? '-';
      sub = next.subText;
    } else {
      active = false;
      title = next.statusLabel ?? '운행 종료';
      sub = next.status == ShuttleStatus.closed
          ? '오늘 예정된 버스가 없어요'
          : next.subText;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kPrimaryTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kPrimaryTint.withValues(alpha: 0.6),
              border: const Border(bottom: BorderSide(color: _kPrimaryTint)),
            ),
            child: Row(
              children: [
                Text(
                  '다음 버스',
                  style: AppTextStyles.caption04.copyWith(
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '실시간',
                  style: AppTextStyles.caption04.copyWith(color: _kPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 아이콘 이미지가 자체 배경 타일을 포함하므로 별도 타일 없이 쓴다.
                Image.asset(
                  'assets/icons/bus/bus.png',
                  width: 52,
                  height: 52,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.title02.copyWith(
                          color: active ? _kPrimary : _kTextStrong,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (sub != null && sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption04.copyWith(
                            color: _kTextMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RefreshIconButton(
                  onRefresh: onRefresh,
                  size: 22,
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

// ───────────────────────────────────────────────────────────────────────────
// 전체 시간표
// ───────────────────────────────────────────────────────────────────────────

class _TimetableSectionHeader extends StatelessWidget {
  final String routeLabel;

  const _TimetableSectionHeader({required this.routeLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(
            '전체 시간표',
            style: AppTextStyles.caption01.copyWith(color: _kTextPrimary),
          ),
          const Spacer(),
          Text(
            routeLabel,
            style: AppTextStyles.caption03.copyWith(color: _kTextMuted),
          ),
        ],
      ),
    );
  }
}

/// 전체 시간표 카드.
///
/// 시(hour)별 한 줄에 출발 분을 정렬된 숫자 그리드로 나열한다. 색 강조는
/// "다음 출발" 한 곳에만 주고, 지나간 시각은 흐리게, 수시운행·도착버스 구간은
/// 회색 띠로 눌러서 시선이 분산되지 않게 한다.
class _TimetableCard extends StatelessWidget {
  final ShuttleTimetable? timetable;

  /// 자정 기준 현재 경과 분 — 지나간 시각 흐림 처리·다음 출발 강조에 사용.
  final int nowMinutes;

  const _TimetableCard({required this.timetable, required this.nowMinutes});

  @override
  Widget build(BuildContext context) {
    final entries = timetable?.entries ?? const <ShuttleEntry>[];

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: _kBgBase,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          '오늘은 셔틀을 운행하지 않아요',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption03.copyWith(color: _kTextMuted),
        ),
      );
    }

    // 강조 대상 하나만 고른다: 지금 진행 중인 구간이 있으면 그 구간, 없으면
    // 현재 시각 이후 첫 정시 출발.
    final activeSegment = entries.cast<ShuttleEntry?>().firstWhere(
          (e) => e!.isSegment && e.covers(nowMinutes),
          orElse: () => null,
        );
    final int? nextFixedMinutes = activeSegment != null
        ? null
        : entries
            .cast<ShuttleEntry?>()
            .firstWhere(
              (e) => !e!.isSegment && e.time.minutesOfDay >= nowMinutes,
              orElse: () => null,
            )
            ?.time
            .minutesOfDay;

    // entries(오름차순)를 순서대로 훑으며 연속된 정시 출발은 시(hour) 단위로
    // 묶고, 수시운행·도착버스 구간은 시간 흐름상 제자리에 끼워 넣는다.
    final rows = <Widget>[const _TableHeader()];
    int? currentHour;
    var currentTimes = <ShuttleTime>[];

    void flushHour() {
      if (currentHour == null) return;
      rows.add(
        _HourRow(
          hour: currentHour!,
          times: currentTimes,
          nowMinutes: nowMinutes,
          nextMinutes: nextFixedMinutes,
        ),
      );
      currentHour = null;
      currentTimes = <ShuttleTime>[];
    }

    for (final entry in entries) {
      if (entry.isSegment) {
        flushHour();
        rows.add(
          _SegmentRow(
            segment: entry,
            nowMinutes: nowMinutes,
            isActive: identical(entry, activeSegment),
          ),
        );
        continue;
      }
      if (currentHour != entry.time.hour) {
        flushHour();
        currentHour = entry.time.hour;
      }
      currentTimes.add(entry.time);
    }
    flushHour();

    // 행 사이에만 구분선을 넣는다(마지막 행 아래는 카드 테두리가 담당).
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, thickness: 1, color: _kBorder));
      }
      children.add(rows[i]);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: children),
    );
  }
}

// 표 레이아웃 공통값.
const double _kHourColWidth = 44.0;
const double _kMinuteCellWidth = 36.0;
const double _kRowVPad = 12.0;

/// 표 머리글 — "시 / 분" 열 이름과 범례.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption04.copyWith(
      color: _kTextMuted,
      letterSpacing: 0.2,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: _kBgSoft,
      child: Row(
        children: [
          SizedBox(width: _kHourColWidth, child: Text('시', style: style)),
          Text('출발 분', style: style),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text('다음 출발', style: style),
        ],
      ),
    );
  }
}

/// 한 시간대(예: 09시) 행 — 시 라벨 + 분 그리드.
class _HourRow extends StatelessWidget {
  final int hour;
  final List<ShuttleTime> times;
  final int nowMinutes;

  /// 강조할 다음 출발 시각(자정 기준 분). 이 행에 없으면 무시된다.
  final int? nextMinutes;

  const _HourRow({
    required this.hour,
    required this.times,
    required this.nowMinutes,
    required this.nextMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // 행 전체가 지나갔으면 시 라벨도 함께 눌러준다.
    final rowPast = times.last.minutesOfDay < nowMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: _kRowVPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HourLabel(hour: hour, muted: rowPast),
          Expanded(
            child: Wrap(
              spacing: 0,
              runSpacing: 6,
              children: [
                for (final time in times)
                  _MinuteCell(
                    time: time,
                    isPast: time.minutesOfDay < nowMinutes,
                    isNext: time.minutesOfDay == nextMinutes,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 행 왼쪽의 시(hour) 라벨 — 시간별 행과 구간 행이 같은 열 폭을 공유한다.
class _HourLabel extends StatelessWidget {
  final int hour;
  final bool muted;

  const _HourLabel({required this.hour, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kHourColWidth,
      // 분 셀과 세로 중심을 맞추기 위한 미세 여백.
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          hour.toString().padLeft(2, '0'),
          style: AppTextStyles.number02.copyWith(
            fontSize: 15,
            color: muted ? _kTextMuted.withValues(alpha: 0.6) : _kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

/// 출발 분(minute) 셀.
///
/// 고정 폭으로 그리드처럼 정렬되는 숫자. 지나간 시각은 흐리게, 다음 출발
/// 하나만 채워진 파란 알약으로 강조한다.
class _MinuteCell extends StatelessWidget {
  final ShuttleTime time;
  final bool isPast;
  final bool isNext;

  const _MinuteCell({
    required this.time,
    required this.isPast,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final text = time.minute.toString().padLeft(2, '0');

    if (isNext) {
      return SizedBox(
        width: _kMinuteCellWidth,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              text,
              style: AppTextStyles.number02.copyWith(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: _kMinuteCellWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          text,
          style: AppTextStyles.number02.copyWith(
            fontSize: 14,
            fontWeight: isPast ? FontWeight.w400 : FontWeight.w500,
            color: isPast ? _kTextMuted.withValues(alpha: 0.55) : _kTextPrimary,
          ),
        ),
      ),
    );
  }
}

/// 구간 항목(수시운행·도착버스 탑승) 행.
///
/// 시 열에는 구간 시작 시각의 시(hour)를 두고, 오른쪽엔 시간 범위 없이
/// 종류(수시 운행 / 도착버스 탑승)만 회색 라벨로 적는다. 지금 진행 중인
/// 구간이면 파란 글자로 한 번만 강조하고, 끝난 구간은 흐리게 표시한다.
class _SegmentRow extends StatelessWidget {
  final ShuttleEntry segment;
  final int nowMinutes;
  final bool isActive;

  const _SegmentRow({
    required this.segment,
    required this.nowMinutes,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final end = segment.endTime;
    final isArrival = segment.type == ShuttleEntryType.arrivalBoarding;
    final label = isArrival ? '도착버스 탑승' : '수시 운행';
    final note = segment.boardingNote;
    final isPast = !isActive && (end ?? segment.time).minutesOfDay < nowMinutes;

    final Color fg = isActive
        ? _kPrimary
        : isPast
            ? _kTextMuted.withValues(alpha: 0.55)
            : _kTextStrong;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: _kRowVPad),
      color: _kBgSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HourLabel(hour: segment.time.hour, muted: isPast),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        isArrival
                            ? Icons.directions_bus_filled_rounded
                            : Icons.schedule_rounded,
                        size: 15,
                        color: fg,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTextStyles.caption02.copyWith(
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: AppTextStyles.caption04.copyWith(
                      color: isPast
                          ? _kTextMuted.withValues(alpha: 0.55)
                          : _kTextMuted,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Footer note
// ───────────────────────────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  final DateTime lastUpdated;

  const _FooterNote({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final hh = lastUpdated.hour.toString().padLeft(2, '0');
    final mm = lastUpdated.minute.toString().padLeft(2, '0');
    final style = AppTextStyles.caption04.copyWith(
      color: _kTextMuted,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );
    return Column(
      children: [
        Text('시간표는 학교 사정에 따라 변경될 수 있어요.', style: style),
        Text('마지막 업데이트 · 오늘 $hh:$mm', style: style),
      ],
    );
  }
}
