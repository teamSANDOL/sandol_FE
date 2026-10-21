import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/map/component/map_common.dart';
import 'package:handori/features/map/data/tuk_place.dart';
import 'package:handori/features/map/presentation/provider/tuk_world_provider.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// TUK 월드 분류. [all]은 필터 없음. 서버 분류 문자열과 [label]이 같다.
enum TukCategory {
  all('전체', Icons.grid_view_rounded),
  leisure('여가', Icons.local_activity_outlined),
  food('식당', Icons.restaurant),
  bar('술집', Icons.sports_bar_outlined);

  final String label;
  final IconData icon;
  const TukCategory(this.label, this.icon);

  bool matches(TukPlace p) => this == all || p.category == label;

  /// 마커 아이콘용. 모르는 분류는 식당으로 그린다.
  static IconData iconOf(TukPlace p) =>
      values
          .firstWhere(
            (c) => c != all && c.label == p.category,
            orElse: () => food,
          )
          .icon;
}

/// TUK 월드 시트. 분류를 고르기 전에는 큰 타일(2544:18760), 고르면 작은
/// 타일 줄 + 업체 목록(2544:18937). 고른 분류를 다시 누르면 처음으로 돌아간다.
class TukWorldPanel extends ConsumerWidget {
  const TukWorldPanel({
    super.key,
    required this.controller,
    required this.category,
    required this.onCategory,
    required this.onPlaceTap,
  });

  final ScrollController controller;
  final TukCategory? category;
  final ValueChanged<TukCategory?> onCategory;
  final ValueChanged<TukPlace> onPlaceTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = category;
    final async = ref.watch(tukWorldPlacesProvider);
    final places = async.valueOrNull;

    final tiles = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final c in TukCategory.values)
          FacilityTile(
            label: c.label,
            icon: c.icon,
            size: picked == null ? 67 : 47,
            selected: c == picked,
            labelStyle:
                picked == null
                    ? SandolTypography.headline
                    : SandolTypography.caption,
            onTap: () => onCategory(c == picked ? null : c),
          ),
      ],
    );

    Widget body;
    if (places == null) {
      body =
          async.hasError
              ? ErrorRetryView(
                title: 'TUK 월드 정보를 불러오지 못했어요',
                onRetry: () => ref.invalidate(tukWorldPlacesProvider),
              )
              : const Padding(
                padding: EdgeInsets.all(SandolSpacing.xl),
                child: Center(child: SandolLoadingIndicator()),
              );
    } else if (picked == null) {
      body = const SizedBox.shrink();
    } else {
      final list = places.where(picked.matches).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${picked.label}  '),
                TextSpan(
                  text: '${list.length}곳',
                  style: SandolTypography.headline.accent,
                ),
              ],
            ),
            style: SandolTypography.headline,
          ),
          const SizedBox(height: SandolSpacing.md),
          if (list.isEmpty)
            Text('등록된 제휴 업체가 없어요', style: SandolTypography.caption.muted),
          for (final p in list)
            Padding(
              padding: const EdgeInsets.only(bottom: SandolSpacing.md),
              child: _PlaceRow(place: p, onTap: () => onPlaceTap(p)),
            ),
        ],
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        SandolSpacing.sm,
        SandolMetrics.pageGutter,
        SandolSpacing.xl,
      ),
      children: [
        if (picked == null) ...[
          const Text('표시할 시설 선택', style: SandolTypography.headline),
          const SizedBox(height: SandolSpacing.lg),
        ],
        tiles,
        const SizedBox(height: SandolSpacing.lg),
        body,
      ],
    );
  }
}

/// 업체 썸네일. 이미지가 없거나 못 불러오면 분류 아이콘 타일.
class _Thumb extends StatelessWidget {
  const _Thumb(this.place, {required this.width, required this.height});

  final TukPlace place;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: MapColors.tile,
      alignment: Alignment.center,
      child: Icon(TukCategory.iconOf(place), color: SandolColors.primary),
    );
    final urls = place.imageUrls;
    return ClipRRect(
      borderRadius: SandolMetrics.radius,
      child: SizedBox(
        width: width,
        height: height,
        child:
            urls.isEmpty
                ? fallback
                : Image.network(
                  urls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
      ),
    );
  }
}

/// 업체 한 줄: 사진 · 이름 · 혜택 두 줄 (2544:18937 Frame 2147235253)
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});

  final TukPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: SandolMetrics.radius,
    child: Row(
      children: [
        _Thumb(place, width: 90, height: 80),
        const SizedBox(width: SandolSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SandolTypography.headline,
              ),
              const SizedBox(height: SandolSpacing.sm),
              Text(
                place.discountInfo ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SandolTypography.caption.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 업체 상세 (Figma '표시한 시설 상세보기' 2541:18446 배치).
///
/// 시안의 운영시간 표 자리에 제휴 혜택을, 비고 자리에 주소를 둔다
/// (TUK 월드 API에 운영시간이 없다).
class TukPlaceDetail extends StatelessWidget {
  const TukPlaceDetail({
    super.key,
    required this.controller,
    required this.place,
    required this.onBack,
    required this.onDirections,
    required this.onShowOnMap,
  });

  final ScrollController controller;
  final TukPlace place;
  final VoidCallback onBack;
  final VoidCallback onDirections;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: const EdgeInsets.fromLTRB(
      SandolMetrics.pageGutter,
      SandolSpacing.sm,
      SandolMetrics.pageGutter,
      SandolSpacing.xl,
    ),
    children: [
      Row(
        children: [
          IconButton(
            tooltip: '뒤로',
            visualDensity: VisualDensity.compact,
            onPressed: onBack,
            icon: SvgPicture.asset(SandolAssets.backArrow),
          ),
          Expanded(
            child: Text(
              place.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SandolTypography.headline,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
      const SizedBox(height: SandolSpacing.md),
      if (place.imageUrls.isNotEmpty) ...[
        _Thumb(place, width: double.infinity, height: 116),
        const SizedBox(height: SandolSpacing.sm),
      ],
      Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: place.name),
                  if (place.category != null)
                    TextSpan(
                      text: '  ${place.category}',
                      style: SandolTypography.caption.muted,
                    ),
                ],
              ),
              style: SandolTypography.headline,
            ),
          ),
          SizedBox(
            width: 158,
            child: MapButton(
              label: '길찾기',
              icon: Icons.near_me_outlined,
              onTap: onDirections,
            ),
          ),
        ],
      ),
      const SizedBox(height: SandolSpacing.md),
      const Divider(height: 1, color: MapColors.line),
      const SizedBox(height: SandolSpacing.md),
      const Text('이용 안내', style: SandolTypography.headline),
      const SizedBox(height: SandolSpacing.md),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: SandolMetrics.radius,
          border: Border.all(color: MapColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('제휴 혜택', style: SandolTypography.body),
            const SizedBox(height: SandolSpacing.sm),
            Text(
              place.discountInfo ?? '등록된 혜택 정보가 없어요',
              style: SandolTypography.body.muted,
            ),
          ],
        ),
      ),
      if (place.address != null) ...[
        const SizedBox(height: SandolSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 60,
              child: Text('주소', style: SandolTypography.body),
            ),
            Expanded(
              child: Text(place.address!, style: SandolTypography.body.muted),
            ),
          ],
        ),
      ],
      const SizedBox(height: SandolSpacing.lg),
      MapButton(
        label: '지도에서 위치 보기',
        icon: Icons.place_outlined,
        onTap: onShowOnMap,
      ),
    ],
  );
}
