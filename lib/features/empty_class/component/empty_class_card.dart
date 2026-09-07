import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/features/empty_class/component/classroom_time_range_picker.dart';
import 'package:handori/features/empty_class/domain/model/building_sort.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/domain/model/nearby_empty_class.dart';
import 'package:handori/features/empty_class/presentation/provider/building_sort_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 홈의 빈 강의실 카드.
///
/// 지금부터 그날 마지막 정각(22:00)까지를 1시간 칸으로 깔고 두 손잡이로 공강
/// 구간을 잡으면, 그 구간 내내 비어 있는 강의실을 가까운 건물 순으로 보여준다.
/// 축의 기준 시각은 조회 상태에 고정돼 있어 다시 그려도 흔들리지 않는다.
class EmptyClassTimelineCard extends ConsumerStatefulWidget {
  final int maxItems;

  /// 건물 행을 눌렀을 때. 건물명(예: `E동`)을 넘긴다.
  final ValueChanged<String>? onBuildingTap;

  const EmptyClassTimelineCard({
    super.key,
    this.maxItems = 3,
    this.onBuildingTap,
  });

  @override
  ConsumerState<EmptyClassTimelineCard> createState() =>
      _EmptyClassTimelineCardState();
}

class _EmptyClassTimelineCardState
    extends ConsumerState<EmptyClassTimelineCard> {
  /// 슬라이더를 끄는 동안의 미리보기 구간 (놓으면 null)
  ClassroomQuery? _preview;

  @override
  void initState() {
    super.initState();
    // 앱을 오래 켜 둔 뒤 돌아오면 구간 시작이 과거일 수 있다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(classroomQueryControllerProvider.notifier).syncToNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(classroomQueryControllerProvider);
    final nearbyAsync = ref.watch(nearbyEmptyClassesProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final sortMode = ref.watch(buildingSortControllerProvider).valueOrNull?.mode ??
        BuildingSort.distance;

    final previewQuery = _preview ?? query;

    final items = nearbyAsync.valueOrNull;
    final refreshing = nearbyAsync.isLoading && items != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClassroomTimeRangePicker(
            onPreview: (q) => setState(() => _preview = q),
          ),
          const SizedBox(height: 8),
          _Summary(query: previewQuery, items: items, refreshing: refreshing),
          const SizedBox(height: 4),
          _SortBar(
            mode: sortMode,
            locationAsync: locationAsync,
            onRetry: () => ref.invalidate(userLocationProvider),
            onOpenSettings: () => _openSortSheet(
              context,
              items?.map((e) => e.building.className).toList() ?? const [],
            ),
          ),
          if (query.isWeekend || query.isAfterClassDay) ...[
            const SizedBox(height: 8),
            const _Callout(
              text: '수업이 없는 시간이라 모든 강의실이 비어 있어요.',
            ),
          ],
          const SizedBox(height: 6),
          const Divider(height: 8, thickness: 0.8, color: AppColors.cardBorder),
          nearbyAsync.when(
            loading: () => items == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: SandolLoadingIndicator()),
                  )
                : _BuildingList(
                    items: items,
                    maxItems: widget.maxItems,
                    dimmed: true,
                    onBuildingTap: widget.onBuildingTap,
                  ),
            error: (e, _) => _ErrorRow(
              onRetry: () => ref.invalidate(emptyClassesProvider),
            ),
            data: (data) => _BuildingList(
              items: data,
              maxItems: widget.maxItems,
              onBuildingTap: widget.onBuildingTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 정렬 설정 시트 ────────────────────────────────────────────────────────────

extension on _EmptyClassTimelineCardState {
  Future<void> _openSortSheet(BuildContext context, List<String> buildings) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _SortSheet(buildings: buildings),
    );
  }
}

/// 정렬 방식 선택 + 내 순서 편집. 변경은 즉시 저장된다.
class _SortSheet extends ConsumerWidget {
  final List<String> buildings;
  const _SortSheet({required this.buildings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(buildingSortControllerProvider).valueOrNull ??
        const BuildingSortSettings();
    final ctrl = ref.read(buildingSortControllerProvider.notifier);
    final order = ctrl.mergedOrder(buildings);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text('정렬 설정',
                style: AppTextStyles.title03.copyWith(color: Colors.black87)),
            const SizedBox(height: 10),
            for (final mode in BuildingSort.values)
              _SortOption(
                mode: mode,
                selected: settings.mode == mode,
                onTap: () => ctrl.setMode(mode),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: settings.mode == BuildingSort.custom
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _ReorderList(
                        order: order,
                        onReorder: (from, to) {
                          final next = List<String>.from(order);
                          final moved = next.removeAt(from);
                          next.insert(to > from ? to - 1 : to, moved);
                          ctrl.setCustomOrder(next);
                        },
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final BuildingSort mode;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon => switch (mode) {
        BuildingSort.distance => Icons.my_location_rounded,
        BuildingSort.count => Icons.meeting_room_outlined,
        BuildingSort.custom => Icons.drag_handle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(_icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mode.label,
                style: AppTextStyles.caption01.copyWith(
                  color: selected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.primary : const Color(0xFFCCD3DA),
            ),
          ],
        ),
      ),
    );
  }
}

/// 햄버거(☰)를 잡고 끌어 순서를 바꾸는 목록.
/// 홈에 보이는 상위 [_rankedCount] 개만 순위 숫자를 단다.
class _ReorderList extends StatelessWidget {
  final List<String> order;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ReorderList({required this.order, required this.onReorder});

  static const int _rankedCount = 3;

  @override
  Widget build(BuildContext context) {
    if (order.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '정렬할 건물이 아직 없어요.',
          style: AppTextStyles.caption03.copyWith(color: Colors.black45),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        itemCount: order.length,
        onReorder: onReorder,
        proxyDecorator: (child, _, _) => Material(
          color: Colors.transparent,
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
        itemBuilder: (context, i) {
          final name = order[i];
          return Container(
            key: ValueKey(name),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              color: AppColors.subtleBg,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child: i < _rankedCount
                      ? Text(
                          '${i + 1}',
                          style: AppTextStyles.caption04.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: AppTextStyles.caption01
                          .copyWith(color: Colors.black87)),
                ),
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.drag_handle_rounded,
                        size: 22, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── 요약 한 줄: 요일 알약 + 구간 + 개수 ──────────────────────────────────────

class _Summary extends StatelessWidget {
  final ClassroomQuery query;
  final List<NearbyEmptyClass>? items;
  final bool refreshing;

  const _Summary({
    required this.query,
    required this.items,
    required this.refreshing,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        items?.fold<int>(0, (s, e) => s + e.building.emptyCount);
    final countText = total == null ? '…' : '$total곳';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${query.dayShort} ${query.timeLabel}',
            style: AppTextStyles.caption04.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTextStyles.caption04.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                const TextSpan(text: '빈 강의실 '),
                TextSpan(
                  text: countText,
                  style: AppTextStyles.caption02.copyWith(
                    color: refreshing
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (refreshing)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

// ── 정렬 상태 줄: 현재 정렬 + 설정 아이콘 ────────────────────────────────────

class _SortBar extends StatelessWidget {
  final BuildingSort mode;
  final AsyncValue locationAsync;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _SortBar({
    required this.mode,
    required this.locationAsync,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final locating = locationAsync.isLoading;
    final hasLocation = locationAsync.valueOrNull != null;
    final needsLocation = mode == BuildingSort.distance;
    final locationMissing = needsLocation && !locating && !hasLocation;

    final IconData icon = switch (mode) {
      BuildingSort.distance =>
        locationMissing ? Icons.location_off_rounded : Icons.my_location_rounded,
      BuildingSort.count => Icons.meeting_room_outlined,
      BuildingSort.custom => Icons.drag_handle_rounded,
    };
    final String hint = switch ((mode, locating, locationMissing)) {
      (BuildingSort.distance, true, _) => ' · 위치 확인 중',
      (BuildingSort.distance, _, true) => ' · 위치 없음, 많은 순으로 표시',
      _ => '',
    };

    return Row(
      children: [
        Icon(icon,
            size: 13,
            color: locationMissing ? AppColors.textMuted : AppColors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTextStyles.caption04.copyWith(color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: mode.label,
                  style: AppTextStyles.caption04.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: hint),
              ],
            ),
          ),
        ),
        if (locationMissing)
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '다시 시도',
                style: AppTextStyles.caption04.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(width: 2),
        Tooltip(
          message: '정렬 설정',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onOpenSettings,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icon/emptyclass_setting.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 건물 목록 ─────────────────────────────────────────────────────────────────

class _BuildingList extends StatelessWidget {
  final List<NearbyEmptyClass> items;
  final int maxItems;
  final bool dimmed;
  final ValueChanged<String>? onBuildingTap;

  const _BuildingList({
    required this.items,
    required this.maxItems,
    this.dimmed = false,
    this.onBuildingTap,
  });

  @override
  Widget build(BuildContext context) {
    final withRooms =
        items.where((e) => e.building.emptyCount > 0).take(maxItems).toList();

    if (withRooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          '이 시간에 비어 있는 강의실이 없어요. 구간을 줄여 보세요.',
          style: AppTextStyles.caption03.copyWith(color: Colors.black45),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.55 : 1,
      child: Column(
        children: [
          for (var i = 0; i < withRooms.length; i++) ...[
            _BuildingRow(item: withRooms[i], onBuildingTap: onBuildingTap),
            if (i != withRooms.length - 1)
              const Divider(
                  height: 10, thickness: 0.8, color: AppColors.cardBorder),
          ],
        ],
      ),
    );
  }
}

class _BuildingRow extends StatelessWidget {
  final NearbyEmptyClass item;
  final ValueChanged<String>? onBuildingTap;

  const _BuildingRow({required this.item, this.onBuildingTap});

  /// 건물당 미리 보여줄 호실 수. 나머지는 `+N`.
  static const int _previewRooms = 4;

  @override
  Widget build(BuildContext context) {
    final b = item.building;
    final walk = item.walkMinutes;
    final preview = b.classList.take(_previewRooms).toList();
    final rest = b.classList.length - preview.length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onBuildingTap == null ? null : () => onBuildingTap!(b.className),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    b.className,
                    style: AppTextStyles.caption01
                        .copyWith(color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: walk == null
                      ? const SizedBox.shrink()
                      : Text(
                          '도보 $walk분',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption04.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBg,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${b.emptyCount}곳',
                    style: AppTextStyles.caption04.copyWith(
                      color: Colors.black87,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final room in preview) _RoomChip(label: room),
                  if (rest > 0) _RoomChip(label: '+$rest', dim: true),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final bool dim;
  const _RoomChip({required this.label, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: dim ? AppColors.subtleBg : AppColors.primaryLight,
        border: Border.all(
            color: dim ? AppColors.cardBorder : AppColors.primaryBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption04.copyWith(
          fontSize: 11,
          color: dim ? AppColors.textSecondary : const Color(0xFF006FA8),
          fontWeight: dim ? FontWeight.w500 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ── 안내 / 에러 ───────────────────────────────────────────────────────────────

class _Callout extends StatelessWidget {
  final String text;
  const _Callout({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        border: Border.all(color: const Color(0xFFF5E2A8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption04.copyWith(
          color: const Color(0xFF6B4E00),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '빈 강의실 정보를 불러올 수 없습니다.',
              style: AppTextStyles.caption03.copyWith(color: Colors.black54),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
