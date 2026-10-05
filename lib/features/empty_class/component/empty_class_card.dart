import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/component/classroom_time_range_picker.dart';
import 'package:handori/features/empty_class/domain/model/building_sort.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/domain/model/nearby_empty_class.dart';
import 'package:handori/features/empty_class/presentation/provider/building_sort_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';
import 'package:handori/core/constants/app_radius.dart';

/// 홈의 빈 강의실 카드 (Figma 2153:303).
///
/// 지금부터 그날 마지막 정각(22:00)까지를 축으로 두 손잡이로 공강 구간을
/// 잡으면, 그 구간 내내 비어 있는 강의실을 가까운 건물 순으로 보여준다.
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
    final sortMode =
        ref.watch(buildingSortControllerProvider).valueOrNull?.mode ??
        BuildingSort.distance;

    final items = nearbyAsync.valueOrNull;
    final refreshing = nearbyAsync.isLoading && items != null;

    Widget list(List<NearbyEmptyClass> data, {bool dimmed = false}) =>
        _BuildingList(
          items: data,
          maxItems: widget.maxItems,
          dimmed: dimmed,
          showWalk: sortMode == BuildingSort.distance,
          onBuildingTap: widget.onBuildingTap,
        );

    return SandolCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SandolMetrics.cardInset,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassroomTimeRangePicker(
            onPreview: (q) => setState(() => _preview = q),
          ),
          const SizedBox(height: SandolSpacing.md),
          _Summary(
            query: _preview ?? query,
            items: items,
            refreshing: refreshing,
          ),
          if (query.isWeekend || query.isAfterClassDay) ...[
            const SizedBox(height: SandolSpacing.sm),
            SandolIconLabel.note('수업이 없는 시간이라 모든 강의실이 비어 있어요.'),
          ],
          const SizedBox(height: 14),
          nearbyAsync.when(
            loading:
                () =>
                    items == null
                        ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(child: SandolLoadingIndicator()),
                        )
                        : list(items, dimmed: true),
            error:
                (e, _) => _ErrorRow(
                  onRetry: () => ref.invalidate(emptyClassesProvider),
                ),
            data: list,
          ),
        ],
      ),
    );
  }
}

// ── 정렬 설정 시트 ────────────────────────────────────────────────────────────

/// 홈 빈 강의실 카드의 건물 정렬 설정 시트. 섹션 제목의 설정 아이콘에서 연다.
Future<void> showBuildingSortSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.value),
      ),
    ),
    isScrollControlled: true,
    builder: (_) => const _SortSheet(),
  );
}

/// 정렬 방식 선택 + 내 순서 편집. 변경은 즉시 저장된다.
class _SortSheet extends ConsumerWidget {
  const _SortSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings =
        ref
            .watch(nearbyEmptyClassesProvider)
            .valueOrNull
            ?.map((e) => e.building.className)
            .toList() ??
        const <String>[];
    final settings =
        ref.watch(buildingSortControllerProvider).valueOrNull ??
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
                  borderRadius: BorderRadius.circular(AppRadius.value),
                ),
              ),
            ),
            Text(
              '정렬 설정',
              style: AppTextStyles.title03.copyWith(color: Colors.black87),
            ),
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
              child:
                  settings.mode == BuildingSort.custom
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
      borderRadius: BorderRadius.circular(AppRadius.value),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
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
        proxyDecorator:
            (child, _, _) => Material(
              color: Colors.transparent,
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.value),
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
              borderRadius: BorderRadius.circular(AppRadius.value),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child:
                      i < _rankedCount
                          ? Text(
                            '${i + 1}',
                            style: AppTextStyles.caption04.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.caption01.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
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

// ── 요약 한 줄: 요일 + 구간 · 빈 강의실 개수 ─────────────────────────────────

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
    final total = items?.fold<int>(0, (s, e) => s + e.building.emptyCount);
    final count = SandolTypography.body.strong;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${query.dayShort} ${query.timeLabel}',
            style: SandolTypography.body,
          ),
        ),
        Text(
          '빈 강의실 ${total ?? '…'}곳',
          style: refreshing ? count.muted : count.accent,
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

  /// 도보 시간은 내 위치 정렬일 때만 의미가 있어 그때만 보여준다.
  final bool showWalk;
  final ValueChanged<String>? onBuildingTap;

  const _BuildingList({
    required this.items,
    required this.maxItems,
    this.dimmed = false,
    this.showWalk = true,
    this.onBuildingTap,
  });

  @override
  Widget build(BuildContext context) {
    final withRooms =
        items.where((e) => e.building.emptyCount > 0).take(maxItems).toList();

    if (withRooms.isEmpty) {
      return Text(
        '이 시간에 비어 있는 강의실이 없어요. 구간을 줄여 보세요.',
        style: SandolTypography.caption.muted,
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.55 : 1,
      child: Column(
        spacing: 14,
        children: [
          for (final item in withRooms)
            _BuildingRow(
              item: item,
              showWalk: showWalk,
              onBuildingTap: onBuildingTap,
            ),
        ],
      ),
    );
  }
}

/// `TIP  도보 N분` / `0000호 0000호 000호 +NN` · 오른쪽 `NN곳`
class _BuildingRow extends StatelessWidget {
  final NearbyEmptyClass item;
  final bool showWalk;
  final ValueChanged<String>? onBuildingTap;

  const _BuildingRow({
    required this.item,
    this.showWalk = true,
    this.onBuildingTap,
  });

  /// 건물당 미리 보여줄 호실 수. 나머지는 `+N`.
  static const int _previewRooms = 3;

  @override
  Widget build(BuildContext context) {
    final b = item.building;
    final walk = showWalk ? item.walkMinutes : null;
    final preview = b.classList.take(_previewRooms);
    final rest = b.classList.length - preview.length;
    final rooms = [...preview, if (rest > 0) '+$rest'].join(' ');

    return InkWell(
      borderRadius: SandolMetrics.radius,
      onTap: onBuildingTap == null ? null : () => onBuildingTap!(b.className),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Text(b.className, style: SandolTypography.body.strong),
                    if (walk != null)
                      Text('도보 $walk분', style: SandolTypography.caption),
                  ],
                ),
                if (rooms.isNotEmpty)
                  Text(
                    rooms,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SandolTypography.caption.muted,
                  ),
              ],
            ),
          ),
          const SizedBox(width: SandolSpacing.sm),
          Text('${b.emptyCount}곳', style: SandolTypography.caption),
        ],
      ),
    );
  }
}

// ── 에러 ──────────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '빈 강의실 정보를 불러올 수 없습니다.',
            style: SandolTypography.caption.muted,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text('다시 시도', style: SandolTypography.caption.accent),
        ),
      ],
    );
  }
}
