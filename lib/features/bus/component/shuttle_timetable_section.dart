import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handol/common/component/handol_card.dart';
import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handol/features/bus/domain/model/shuttle_schedule.dart';

/// 한 방향의 시간표 카드 제목과 내용.
typedef ShuttleTimetableCardData =
    ({String title, ShuttleTimetable? timetable});

/// 전체 시간표 구역 (Figma 2683:2828 안 2905:1985 · 2905:1921 · 2905:2249 · 2905:2320).
///
/// '전체 시간표' 제목 + 요일 배지, '지난 시간 보기' 접기 줄, 방향마다 시간표
/// 카드, 맨 아래 안내문. 다 지나간 줄은 접어 두어 지금 시각 이후부터 보인다.
/// 지난 시간 펼침은 모든 카드가 함께 따른다.
class ShuttleTimetableSection extends StatefulWidget {
  const ShuttleTimetableSection({
    super.key,
    required this.cards,
    required this.now,
    required this.needsReview,
  });

  final List<ShuttleTimetableCardData> cards;

  /// 기준 시각. 지난 줄 판정, 요일 배지, 마지막 업데이트에 쓴다.
  final DateTime now;

  /// 서버가 최신 시간표 검증에 실패해 직전 정상본을 주는 중인지.
  final bool needsReview;

  @override
  State<ShuttleTimetableSection> createState() =>
      _ShuttleTimetableSectionState();
}

class _ShuttleTimetableSectionState extends State<ShuttleTimetableSection> {
  bool _showPast = false;

  static String _dayLabel(ShuttleDayType type) => switch (type) {
    ShuttleDayType.weekday => '평일',
    ShuttleDayType.saturday => '토요일',
    ShuttleDayType.sunday => '일요일',
    ShuttleDayType.holiday => '공휴일',
  };

  @override
  Widget build(BuildContext context) {
    final nowMinutes = widget.now.hour * 60 + widget.now.minute;
    final hasPast = widget.cards.any(
      (c) => (c.timetable?.entries ?? const <ShuttleEntry>[]).any(
        (e) => _isPast(e, nowMinutes),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(dayLabel: _dayLabel(ShuttleScheduleData.dayTypeOf(widget.now))),
        if (hasPast) ...[
          const SizedBox(height: HandolSpacing.sm),
          _PastToggle(
            expanded: _showPast,
            onTap: () => setState(() => _showPast = !_showPast),
          ),
        ],
        for (final card in widget.cards) ...[
          const SizedBox(height: 20),
          _TimetableCard(
            title: card.title,
            timetable: card.timetable,
            nowMinutes: nowMinutes,
            showPast: _showPast,
          ),
        ],
        const SizedBox(height: HandolSpacing.lg),
        _FooterNote(lastUpdated: widget.now, needsReview: widget.needsReview),
      ],
    );
  }
}

bool _isPast(ShuttleEntry e, int nowMinutes) =>
    e.isSegment
        ? e.endTime != null && e.endTime!.minutesOfDay <= nowMinutes
        : e.time.minutesOfDay < nowMinutes;

/// '전체 시간표' + 요일 배지 (2905:1985)
class _Header extends StatelessWidget {
  const _Header({required this.dayLabel});

  final String dayLabel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: HandolSpacing.sm,
    children: [
      const Flexible(child: Text('전체 시간표', style: HandolTypography.title)),
      DecoratedBox(
        decoration: BoxDecoration(
          color: HandolColors.background,
          border: Border.all(color: HandolColors.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(dayLabel, style: HandolTypography.body.strong.accent),
        ),
      ),
    ],
  );
}

/// 접어 둔 지난 시간을 펼치고 접는 줄 (2905:1921)
class _PastToggle extends StatelessWidget {
  const _PastToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: HandolColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: HandolMetrics.radius,
      side: const BorderSide(color: HandolColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                expanded ? '지난 시간 접기' : '지난 시간 보기',
                style: HandolTypography.caption,
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: HandolColors.text,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 한 방향의 시간표 카드 (2905:2249 · 2905:2320).
/// 시간 줄마다 버스 아이콘, 다음 출발 · 수시 운행 · 막차는 오른쪽 배지.
class _TimetableCard extends StatelessWidget {
  const _TimetableCard({
    required this.title,
    required this.timetable,
    required this.nowMinutes,
    required this.showPast,
  });

  final String title;
  final ShuttleTimetable? timetable;
  final int nowMinutes;
  final bool showPast;

  @override
  Widget build(BuildContext context) {
    final entries = timetable?.entries ?? const <ShuttleEntry>[];
    // 다음 버스 카드와 같은 기준: 지금 이후 첫 정시편.
    final next =
        entries
            .where((e) => !e.isSegment && e.time.minutesOfDay >= nowMinutes)
            .firstOrNull;
    // 정시편으로 하루가 끝날 때만 막차. 뒤에 수시운행이 이어지면 막차가 아니다.
    final last = entries.lastOrNull;
    final shown = [
      for (final e in entries)
        if (showPast || !_isPast(e, nowMinutes)) e,
    ];
    final hasUpcoming = entries.any((e) => !_isPast(e, nowMinutes));

    return HandolCard(
      padding: const EdgeInsets.only(top: 12, bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title, style: HandolTypography.body.strong.accent),
          ),
          const SizedBox(height: 2),
          if (entries.isEmpty)
            const _CenteredNote('오늘은 셔틀을 운행하지 않아요')
          else ...[
            for (final e in shown)
              _EntryRow(
                entry: e,
                past: _isPast(e, nowMinutes),
                isNext: identical(e, next),
                isLast: !e.isSegment && identical(e, last),
              ),
            if (!hasUpcoming) const _CenteredNote('오늘 남은 셔틀이 없어요'),
          ],
        ],
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: HandolTypography.body.inactive,
  );
}

/// `🚌 14:35            [다음 출발]` (시안: 왼쪽 17, 오른쪽 21, 줄 높이 24)
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.past,
    required this.isNext,
    required this.isLast,
  });

  final ShuttleEntry entry;
  final bool past;
  final bool isNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final end = e.endTime;
    final time = switch ((e.isSegment, end)) {
      (false, _) => e.time.label,
      (true, null) => '${e.time.label} 이후',
      (true, final ShuttleTime end) => '${e.time.label} ~ ${end.label}',
    };
    final color =
        past
            ? HandolColors.inactive
            : isNext
            ? HandolColors.primary
            : HandolColors.textSecondary;
    // (라벨, 글자색, 테두리색)
    final badge = switch (e.type) {
      ShuttleEntryType.flexible => (
        '수시 운행',
        HandolColors.orange,
        HandolColors.orange,
      ),
      ShuttleEntryType.arrivalBoarding => (
        '도착버스 탑승',
        HandolColors.orange,
        HandolColors.orange,
      ),
      _ when isLast => ('막차', HandolColors.text, HandolColors.textSecondary),
      _ when isNext => ('다음 출발', HandolColors.primary, HandolColors.border),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(left: 17, right: 21),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Row(
          spacing: HandolSpacing.sm,
          children: [
            Expanded(
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
                      child: Text(
                        note,
                        style: HandolTypography.caption.inactive,
                      ),
                    ),
                ],
              ),
            ),
            if (badge case (
              final String label,
              final Color text,
              final Color line,
            ))
              _Badge(
                label: label,
                textColor: past ? HandolColors.inactive : text,
                borderColor: past ? HandolColors.inactive : line,
              ),
          ],
        ),
      ),
    );
  }
}

/// 둥근 상태 배지 (시안 65×27, 모서리 30, 글자 14 굵게)
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 65, minHeight: 27),
    padding: const EdgeInsets.symmetric(horizontal: HandolSpacing.sm),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: HandolColors.background,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: HandolTypography.caption.strong.copyWith(color: textColor),
    ),
  );
}

/// 맨 아래 안내문 (2683:2995)
class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.lastUpdated, required this.needsReview});

  final DateTime lastUpdated;
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
