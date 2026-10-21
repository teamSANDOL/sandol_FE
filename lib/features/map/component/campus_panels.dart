import 'package:flutter/material.dart';
import 'package:handori/common/component/coming_soon_snackbar.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/map/component/map_common.dart';

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
    children: children,
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
      SandolMetrics.pageGutter,
      SandolSpacing.sm,
      SandolMetrics.pageGutter,
      SandolSpacing.lg,
    ),
    children: [
      Row(
        children: [
          Expanded(
            child: Text('지금 많이 찾는 시설', style: SandolTypography.headline.accent),
          ),
          InkWell(
            onTap: onShowAll,
            borderRadius: SandolMetrics.radius,
            child: const Row(
              children: [
                Text('전체보기', style: SandolTypography.caption),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: SandolSpacing.md),
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
      SandolMetrics.pageGutter,
      SandolSpacing.sm,
      SandolMetrics.pageGutter,
      SandolSpacing.lg,
    ),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text('표시할 시설 선택', style: SandolTypography.headline),
          ),
          IconButton(
            tooltip: '닫기',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      const SizedBox(height: SandolSpacing.md),
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

/// 지도에서 고른 건물 시트 (2548:19361), [expanded]면 상세보기 (2548:20479).
///
/// 건물 사진 · 학과 · 소개 · 층별 안내 · 캠퍼스 안내도는 데이터가 없어
/// 건물 아이콘과 빈 강의실 수로 대신하고, 상세에는 준비중 문구를 둔다.
class BuildingPanel extends StatelessWidget {
  const BuildingPanel({
    super.key,
    required this.controller,
    required this.building,
    required this.expanded,
    required this.onDirections,
    required this.onDetail,
    required this.onEmptyClass,
  });

  final ScrollController controller;
  final EmptyClass building;
  final bool expanded;
  final VoidCallback? onDirections;
  final VoidCallback onDetail;
  final VoidCallback onEmptyClass;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Container(
          width: 100,
          height: 80,
          padding: const EdgeInsets.all(SandolSpacing.md),
          decoration: const BoxDecoration(
            color: MapColors.tile,
            borderRadius: SandolMetrics.radius,
          ),
          child: Image.asset(building.classIcons, fit: BoxFit.contain),
        ),
        const SizedBox(width: SandolSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(building.className, style: SandolTypography.headline),
              const SizedBox(height: SandolSpacing.sm),
              Text(
                '빈 강의실 ${building.emptyCount}개',
                style: SandolTypography.caption.muted,
              ),
            ],
          ),
        ),
      ],
    );
    final directions = MapButton(
      label: '길찾기',
      icon: Icons.near_me_outlined,
      onTap: onDirections ?? () => showComingSoonSnackBar(context),
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        SandolSpacing.sm,
        SandolMetrics.pageGutter,
        SandolSpacing.xl,
      ),
      children: [
        header,
        const SizedBox(height: SandolSpacing.sm),
        if (expanded) ...[
          directions,
          const SizedBox(height: SandolSpacing.lg),
          Center(child: Text('시설 정보', style: SandolTypography.caption)),
          const SizedBox(height: SandolSpacing.sm),
          const Divider(height: 1, color: MapColors.line),
          const SizedBox(height: SandolSpacing.lg),
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
            spacing: 29,
            children: [
              _tile(context, CampusFacility.printer, enabled: false),
              _tile(context, CampusFacility.vending, enabled: false),
            ],
          ),
          const SizedBox(height: SandolSpacing.lg),
          Text('건물 소개 · 층별 안내는 준비중이에요', style: SandolTypography.caption.muted),
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
          const SizedBox(height: SandolSpacing.lg),
          const MapSectionTitle('학습 공간'),
          Row(
            spacing: 29,
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
