import 'package:flutter/material.dart';
import 'package:handol/common/component/coming_soon_snackbar.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/features/empty_class/model/class_model.dart';
import 'package:handol/features/map/component/map_common.dart';

// 교내 시설(식당 · 카페 · 편의점 등)은 위치·운영 정보 API가 아직 없어
// 빈 강의실 외 시설은 누르면 '준비중' 안내만 띄운다.

/// 시설 타일 한 줄. 타일 사이를 시안처럼 고르게 벌린다.
class _TileRow extends StatelessWidget {
  const _TileRow(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    // 폭이 넉넉하면 시안대로 양끝 정렬, 좁은 화면(예: 화면 밀도 450 → 폭 384)에서
    // 6칸이 넘치면 칸마다 같은 몫으로 줄인다.
    children: [for (final c in children) Flexible(child: c)],
  );
}

FacilityTile _tile(
  BuildContext context,
  CampusFacility f, {
  VoidCallback? onTap,
  bool enabled = true,
}) => FacilityTile(
  label: f.label,
  icon: f.icon,
  asset: f.asset,
  enabled: enabled,
  onTap: onTap ?? () => showComingSoonSnackBar(context),
);

/// 맵 첫 화면 시트: '지금 많이 찾는 시설' + 전체보기 (2451:1122).
///
/// 탭이 '빈 강의실'에서 '맵'으로 바뀌었으므로 빈 강의실을 첫 바로가기로 둔다
/// (시안에는 없음 — 기존 탭 기능의 진입점을 잃지 않기 위해).
class CampusHomePanel extends StatelessWidget {
  const CampusHomePanel({
    super.key,
    required this.controller,
    required this.onEmptyClass,
    required this.onShowAll,
  });

  final ScrollController controller;
  final VoidCallback onEmptyClass;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: const EdgeInsets.fromLTRB(
      HandolMetrics.pageGutter,
      HandolSpacing.sm,
      HandolMetrics.pageGutter,
      HandolSpacing.lg,
    ),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '지금 많이 찾는 시설',
              style: HandolTypography.headline.strong.accent,
            ),
          ),
          InkWell(
            onTap: onShowAll,
            borderRadius: HandolMetrics.radius,
            child: const Row(
              children: [
                Text('전체보기', style: HandolTypography.caption),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: HandolSpacing.md),
      _TileRow([
        _tile(context, CampusFacility.emptyClass, onTap: onEmptyClass),
        for (final f in const [
          CampusFacility.restaurant,
          CampusFacility.cafe,
          CampusFacility.store,
          CampusFacility.printer,
          CampusFacility.studyRoom,
        ])
          _tile(context, f),
      ]),
    ],
  );
}

/// '표시할 시설 선택' 시트 (2527:2849 맵- 필터 및 레이어).
class FacilityFilterPanel extends StatelessWidget {
  const FacilityFilterPanel({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onEmptyClass,
  });

  final ScrollController controller;

  /// 닫기(X)와 '전체'. 지금 지도에 그릴 수 있는 시설은 건물(빈 강의실)뿐이다.
  final VoidCallback onClose;
  final VoidCallback onEmptyClass;

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: const EdgeInsets.fromLTRB(
      HandolMetrics.pageGutter,
      HandolSpacing.sm,
      HandolMetrics.pageGutter,
      HandolSpacing.lg,
    ),
    children: [
      Row(
        children: [
          Expanded(
            child: Text('표시할 시설 선택', style: HandolTypography.headline.strong),
          ),
          IconButton(
            tooltip: '닫기',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      const SizedBox(height: HandolSpacing.md),
      _TileRow([
        _tile(context, CampusFacility.all, onTap: onClose),
        _tile(context, CampusFacility.emptyClass, onTap: onEmptyClass),
        _tile(context, CampusFacility.restaurant),
        _tile(context, CampusFacility.cafe),
        _tile(context, CampusFacility.printer),
      ]),
      const SizedBox(height: 20),
      _TileRow([
        _tile(context, CampusFacility.studyRoom),
        _tile(context, CampusFacility.store),
        _tile(context, CampusFacility.vending),
        _tile(context, CampusFacility.lounge),
        _tile(context, CampusFacility.etc),
      ]),
    ],
  );
}

/// '선택한 곳 다시 누르기' + X (Figma 2905:2467, 14px 글자 50% · 24px 아이콘 A4ABBD).
class _DeselectButton extends StatelessWidget {
  const _DeselectButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: HandolMetrics.radius,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Flexible(
            child: Text(
              '선택한 곳 다시 누르기',
              textAlign: TextAlign.end,
              style: HandolTypography.caption.muted,
            ),
          ),
          const Icon(
            Icons.close_rounded,
            size: HandolMetrics.iconSize,
            color: HandolColors.inactive,
          ),
        ],
      ),
    ),
  );
}

/// 선택된 탭 하나짜리 탭줄: 글자 + 가는 구분선 위에 얹은 파란 막대 (Figma 2548:20515~20517).
class _InfoTab extends StatelessWidget {
  const _InfoTab(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: HandolTypography.caption),
      const SizedBox(height: 4),
      const SizedBox(
        height: 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Divider(height: 1, thickness: 1, color: MapColors.line),
            SizedBox(
              width: 50,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: HandolColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// 지도에서 고른 건물 시트 (2548:19361), [expanded]면 상세보기 (2548:20479).
///
/// 건물 사진 · 학과(부제) · 하트(즐겨찾기) · 소개 · 층별 안내 · 캠퍼스 안내도는
/// 데이터·기능이 없어 건물 아이콘과 빈 강의실 수로 대신하고(2905:2471),
/// 상세에는 준비중 문구를 둔다.
class BuildingPanel extends StatelessWidget {
  const BuildingPanel({
    super.key,
    required this.controller,
    required this.building,
    required this.expanded,
    required this.onDirections,
    required this.onDetail,
    required this.onEmptyClass,
    required this.onDeselect,
  });

  final ScrollController controller;
  final EmptyClass building;
  final bool expanded;
  final VoidCallback? onDirections;
  final VoidCallback onDetail;
  final VoidCallback onEmptyClass;

  /// '선택한 곳 다시 누르기 X' (Figma 2905:2467): 건물 선택을 풀고 첫 시트로
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Container(
          width: 100,
          height: 80,
          padding: const EdgeInsets.all(HandolSpacing.md),
          decoration: const BoxDecoration(
            color: MapColors.tile,
            borderRadius: HandolMetrics.radius,
          ),
          child: Image.asset(building.classIcons, fit: BoxFit.contain),
        ),
        // 사진과 글 사이 5 (2905:2464 ~ 2905:2472)
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(building.className, style: HandolTypography.headline.strong),
              const SizedBox(height: HandolSpacing.sm),
              Text(
                '빈 강의실 ${building.emptyCount}개',
                style: HandolTypography.caption.muted,
              ),
            ],
          ),
        ),
        Flexible(flex: 2, child: _DeselectButton(onTap: onDeselect)),
      ],
    );
    final directions = MapButton(
      label: '길찾기',
      icon: Icons.near_me_outlined,
      onTap: onDirections ?? () => showComingSoonSnackBar(context),
    );

    return ListView(
      controller: controller,
      // 손잡이 아래 사진까지 4 (Figma 2905:2464 y27)
      padding: const EdgeInsets.fromLTRB(
        HandolMetrics.pageGutter,
        HandolSpacing.xs,
        HandolMetrics.pageGutter,
        HandolSpacing.xl,
      ),
      children: [
        header,
        const SizedBox(height: HandolSpacing.sm),
        if (expanded) ...[
          directions,
          // 길찾기 끝 153 → 탭 글자 199 → 구분선 223 → 주요 시설 259 (2548:20514~20517)
          const SizedBox(height: 46),
          const _InfoTab('시설 정보'),
          const SizedBox(height: 32),
          const MapSectionTitle('주요 시설'),
          _TileRow([
            _tile(context, CampusFacility.emptyClass, onTap: onEmptyClass),
            for (final f in const [
              CampusFacility.studyRoom,
              CampusFacility.restaurant,
              CampusFacility.cafe,
              CampusFacility.store,
            ])
              _tile(context, f, enabled: false),
          ]),
          const SizedBox(height: 20),
          const MapSectionTitle('편의 시설'),
          Row(
            // 타일 폭 55 + 21 = 시안 간격 29 + 타일 47 (2548:20594)
            spacing: 21,
            children: [
              _tile(context, CampusFacility.printer, enabled: false),
              _tile(context, CampusFacility.vending, enabled: false),
            ],
          ),
          const SizedBox(height: HandolSpacing.lg),
          Text('건물 소개 · 층별 안내는 준비중이에요', style: HandolTypography.caption.muted),
        ] else ...[
          Row(
            spacing: 29,
            children: [
              Expanded(child: directions),
              Expanded(
                child: MapButton(
                  label: '상세보기',
                  primary: false,
                  onTap: onDetail,
                ),
              ),
            ],
          ),
          const SizedBox(height: HandolSpacing.lg),
          const MapSectionTitle('학습 공간'),
          Row(
            spacing: 21,
            children: [
              _tile(context, CampusFacility.emptyClass, onTap: onEmptyClass),
              _tile(context, CampusFacility.studyRoom),
              _tile(context, CampusFacility.library),
            ],
          ),
          const SizedBox(height: 20),
          const MapSectionTitle('생활 편의'),
          _TileRow([
            for (final f in const [
              CampusFacility.cafe,
              CampusFacility.restaurant,
              CampusFacility.vending,
              CampusFacility.store,
              CampusFacility.printer,
            ])
              _tile(context, f),
          ]),
        ],
      ],
    );
  }
}
