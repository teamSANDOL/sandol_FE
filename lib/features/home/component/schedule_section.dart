import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_button.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/common/component/sandol_section.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/home/model/schedule_event.dart';

/// 홈 '주요일정' 섹션.
///
/// 고정한 일정이 있으면 일정 카드(2153:222), 없으면 빈 카드(2270:498)를
/// 보여준다. 두 카드 모두 오른쪽 위 X와 오른쪽 아래 '자세히보기'가 있다.
/// X는 카드 모서리에 반쯤 걸쳐 제목 줄까지 올라오므로, 카드만 감싼 Stack
/// 밖으로 나가 윗부분이 눌리지 않는 일이 없게 섹션 전체를 Stack으로 감싼다.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    super.key,
    required this.event,
    required this.today,
    required this.onClose,
    required this.onDetail,
  });

  static const double _closeSize = 32;

  /// 카드 윗변 위로 올라오는 만큼
  static const double _closeLift = 15;

  /// 고정한 일정. 없으면 빈 카드를 보여준다.
  final ScheduleEvent? event;
  final DateTime today;

  /// X. 일정 카드에서는 고정 해제, 빈 카드에서는 섹션 닫기.
  final VoidCallback onClose;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    return Stack(
      children: [
        SandolSection(
          title: '주요일정',
          child:
              event == null
                  ? _EmptyScheduleCard(onDetail: onDetail)
                  : _ScheduleCard(
                    event: event,
                    today: today,
                    onDetail: onDetail,
                  ),
        ),
        Positioned(
          top: SandolSection.titleHeight + SandolSpacing.sm - _closeLift,
          right: 0,
          child: SandolIconButton(
            tooltip: event == null ? '닫기' : '고정 해제',
            size: _closeSize,
            background: SandolColors.primarySoft,
            onTap: onClose,
            icon: Transform.rotate(
              angle: math.pi / 4,
              child: SvgPicture.asset(SandolAssets.close),
            ),
          ),
        ),
      ],
    );
  }
}

/// 고정한 일정 카드 (Figma 2153:222 · 2156:666)
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.event,
    required this.today,
    required this.onDetail,
  });

  final ScheduleEvent event;
  final DateTime today;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) => SandolCard(
    padding: const EdgeInsets.fromLTRB(
      SandolMetrics.cardInset,
      SandolSpacing.md,
      SandolMetrics.cardInset,
      SandolSpacing.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(SandolAssets.star),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      style: SandolTypography.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SandolSpacing.xs),
                    Text(event.periodLabel, style: SandolTypography.body),
                  ],
                ),
              ),
            ),
            _DDayBadge(label: event.dDayOn(today)),
          ],
        ),
        _DetailLink(onTap: onDetail),
      ],
    ),
  );
}

/// 고정한 일정이 없을 때의 카드 (Figma 2270:498).
/// 시안 frame(345×142) 안의 절대 위치를 그대로 따른다.
class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.onDetail});

  static const double _height = 142;

  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) => SandolCard(
    child: SizedBox(
      height: _height,
      child: Stack(
        children: [
          Positioned(
            left: 38,
            top: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(SandolAssets.starMuted),
                const SizedBox(height: 10),
                const Text('아직 고정한 스케줄이 없어요', style: SandolTypography.body),
              ],
            ),
          ),
          const Positioned(
            right: SandolMetrics.cardInset,
            top: 17,
            child: _SleepingMascot(),
          ),
          Positioned(
            right: SandolMetrics.cardInset,
            bottom: 10,
            child: _DetailLink(onTap: onDetail),
          ),
        ],
      ),
    ),
  );
}

/// 잠자는 산돌이. 얼굴(2270:510) 위에 입 · 눈 · Z 두 개를 시안 좌표대로 겹친다.
/// 선 레이어 SVG는 획 두께만큼 노드보다 커서, 그만큼 왼쪽 위로 당겨 놓는다.
class _SleepingMascot extends StatelessWidget {
  const _SleepingMascot();

  static const Size _size = Size(75.5367, 62.2936);

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: _size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(SandolAssets.mascotBase),
        Positioned(
          left: 43.586,
          top: 38.753,
          // 시안에서 좌우 반전된 레이어
          child: Transform.flip(
            flipX: true,
            child: SvgPicture.asset(SandolAssets.mascotMouth),
          ),
        ),
        Positioned(
          left: 17.917,
          top: 32.054,
          child: SvgPicture.asset(SandolAssets.mascotEyes),
        ),
        Positioned(
          left: 57.276,
          top: 18.786,
          child: SvgPicture.asset(SandolAssets.mascotZ1),
        ),
        Positioned(
          left: 66.340,
          top: 9.852,
          child: SvgPicture.asset(SandolAssets.mascotZ2),
        ),
      ],
    ),
  );
}

/// 오른쪽 아래 '자세히보기 >'
class _DetailLink extends StatelessWidget {
  const _DetailLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: SandolMetrics.radius,
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('자세히보기', style: SandolTypography.caption.muted),
        const SizedBox(width: SandolSpacing.sm),
        const SandolChevron(muted: true),
      ],
    ),
  );
}

class _DDayBadge extends StatelessWidget {
  const _DDayBadge({required this.label});

  static const double _size = 60;

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    padding: const EdgeInsets.all(SandolSpacing.xs),
    decoration: const BoxDecoration(
      color: SandolColors.primary,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    // 'D-Day'처럼 긴 라벨도 원 안에 들어가게 줄인다.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: SandolTypography.title.onPrimary),
    ),
  );
}
