import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/component/classroom_time_range_picker.dart';
import 'package:handori/features/empty_class/domain/model/class_period.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/map/component/map_common.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 호실 상태 (2538:17489 범례). 전체 강의실 목록을 못 받으면 빈 호실만 나온다.
enum RoomStatus {
  empty('비어있음', MapColors.soft, SandolColors.primary),
  busy('수업예정', MapColors.busy, MapColors.busyDot);

  final String label;
  final Color fill;
  final Color dot;
  const RoomStatus(this.label, this.fill, this.dot);
}

/// 건물의 호실과 상태. 전체 목록이 있으면 전체를, 없으면 빈 호실만 돌려준다.
List<(String, RoomStatus)> roomsWithStatus(EmptyClass b) {
  final empty = b.classList.toSet();
  final rooms = b.allRooms.isEmpty ? b.classList : b.allRooms;
  return [
    for (final r in rooms)
      (r, empty.contains(r) ? RoomStatus.empty : RoomStatus.busy),
  ];
}

/// 첫 숫자를 층으로 본다 (`217호` → `2층`). 숫자가 없으면 '기타'.
String floorOf(String room) {
  final m = RegExp(r'\d').firstMatch(room);
  return m == null ? '기타' : '${m.group(0)}층';
}

enum _Sort {
  building('건물순'),
  count('빈 강의실 많은순');

  final String label;
  const _Sort(this.label);
}

/// '빈 강의실 현황' 시트 (Figma '맵- 빈강의실 버튼을 누를 시' 2538:17489).
///
/// 조회 시간(지금 · 시간 선택) · 교시 선택 · 강의실 검색 · 정렬 · 범례 ·
/// 건물별 호실 상태 카드. [focusBuilding]이 바뀌면 그 건물 카드로 스크롤한다.
class EmptyClassPanel extends ConsumerStatefulWidget {
  const EmptyClassPanel({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onBuildingTap,
    this.focusBuilding,
  });

  final ScrollController controller;
  final VoidCallback onBack;
  final ValueChanged<EmptyClass> onBuildingTap;
  final String? focusBuilding;

  @override
  ConsumerState<EmptyClassPanel> createState() => _EmptyClassPanelState();
}

class _EmptyClassPanelState extends ConsumerState<EmptyClassPanel> {
  final _search = TextEditingController();
  final Map<String, GlobalKey> _cardKeys = {};
  _Sort _sort = _Sort.building;

  @override
  void initState() {
    super.initState();
    _scheduleFocus();
  }

  @override
  void didUpdateWidget(EmptyClassPanel old) {
    super.didUpdateWidget(old);
    if (old.focusBuilding != widget.focusBuilding) _scheduleFocus();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _scheduleFocus() {
    final name = widget.focusBuilding;
    if (name == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[name]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// 검색어가 건물명에 맞으면 건물 전체를, 아니면 호실 이름에 맞는 호실만 남긴다.
  List<(EmptyClass, List<(String, RoomStatus)>)> _visible(
    List<EmptyClass> items,
  ) {
    final q = _search.text.replaceAll(' ', '');
    final rows = <(EmptyClass, List<(String, RoomStatus)>)>[];
    for (final b in items) {
      final rooms = roomsWithStatus(b);
      if (q.isEmpty || b.className.contains(q)) {
        rows.add((b, rooms));
        continue;
      }
      final hit = rooms.where((r) => '${b.className}${r.$1}'.contains(q));
      if (hit.isNotEmpty) rows.add((b, hit.toList()));
    }
    if (_sort == _Sort.count) {
      rows.sort((a, b) => b.$1.emptyCount.compareTo(a.$1.emptyCount));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(emptyClassesProvider);
    final query = ref.watch(classroomQueryControllerProvider);
    final items = async.valueOrNull;
    final total = items?.fold<int>(0, (s, e) => s + e.emptyCount) ?? 0;
    final rows = items == null ? null : _visible(items);

    return ListView(
      controller: widget.controller,
      // 카드가 미리 빌드돼 있어야 ensureVisible 스크롤이 정확하다
      // (건물 수십 개 수준이라 부담 없음).
      cacheExtent: 4000,
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
              onPressed: widget.onBack,
              icon: SvgPicture.asset(SandolAssets.backArrow),
            ),
            const Expanded(
              child: Text('빈 강의실 현황', style: SandolTypography.headline),
            ),
            Text('총 $total개', style: SandolTypography.caption.muted),
          ],
        ),
        const SizedBox(height: SandolSpacing.xs),
        Text(
          '${query.dayName} ${query.timeLabel} 동안 비어있는 강의실',
          style: SandolTypography.body,
        ),
        const SizedBox(height: SandolSpacing.md),
        _QueryCard(search: _search, onSearch: () => setState(() {})),
        const SizedBox(height: SandolSpacing.md),
        Row(
          children: [
            for (final s in RoomStatus.values) ...[
              _Dot(s.dot, 12),
              const SizedBox(width: SandolSpacing.xs),
              Text(s.label, style: SandolTypography.caption),
              const SizedBox(width: 20),
            ],
            const Spacer(),
            PopupMenuButton<_Sort>(
              tooltip: '정렬',
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder:
                  (_) => [
                    for (final s in _Sort.values)
                      PopupMenuItem(value: s, child: Text(s.label)),
                  ],
              child: _Pill(label: _sort.label, trailing: true),
            ),
          ],
        ),
        const SizedBox(height: SandolSpacing.md),
        if (rows == null)
          async.hasError
              ? ErrorRetryView(
                title: '빈 강의실 정보를 불러오지 못했어요',
                onRetry: () => ref.invalidate(emptyClassesProvider),
              )
              : const Padding(
                padding: EdgeInsets.all(SandolSpacing.xl),
                child: Center(child: SandolLoadingIndicator()),
              )
        else ...[
          for (final (b, rooms) in rows)
            Padding(
              key: _cardKeys.putIfAbsent(b.className, GlobalKey.new),
              padding: const EdgeInsets.only(bottom: SandolSpacing.md),
              child: _BuildingRooms(
                building: b,
                rooms: rooms,
                onTap: () => widget.onBuildingTap(b),
              ),
            ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(SandolSpacing.lg),
              child: Center(
                child: Text(
                  _search.text.isEmpty ? '현재 빈 강의실이 없습니다.' : '검색 결과가 없어요',
                  style: SandolTypography.caption.muted,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// 조회 시간 · 교시 선택 · 강의실 검색 카드 (2538:17489 Frame 2147235294)
class _QueryCard extends ConsumerWidget {
  const _QueryCard({required this.search, required this.onSearch});

  final TextEditingController search;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(classroomQueryControllerProvider);
    final ctrl = ref.read(classroomQueryControllerProvider.notifier);
    final period = periodLabelOf(query.startMinutes, query.endMinutes);
    final isNow = query.startMinutes == query.anchorMinutes && period == null;
    final muted = SandolTypography.caption.muted;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SandolMetrics.radius,
        border: Border.all(color: MapColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('조회 시간', style: muted),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: SandolSpacing.sm,
                      runSpacing: SandolSpacing.sm,
                      children: [
                        _Pill(
                          label: '지금 (현재)',
                          icon: Icons.schedule_rounded,
                          selected: isNow,
                          onTap: ctrl.resetToNow,
                        ),
                        _Pill(
                          label: '시간 선택',
                          selected: !isNow && period == null,
                          onTap: () => showClassroomTimeSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 37,
                margin: const EdgeInsets.fromLTRB(10, 22, 10, 0),
                color: MapColors.line,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('교시 선택', style: muted),
                  const SizedBox(height: 9),
                  PopupMenuButton<({int start, int end})>(
                    tooltip: '교시 선택',
                    onSelected: (p) => ctrl.setRange(p.start, p.end),
                    itemBuilder:
                        (_) => [
                          PopupMenuItem(
                            value: allPeriods,
                            child: const Text('전체 교시'),
                          ),
                          for (var i = 0; i < classPeriods.length; i++)
                            PopupMenuItem(
                              value: classPeriods[i],
                              child: Text('${i + 1}교시'),
                            ),
                        ],
                    child: _Pill(
                      label: period ?? '교시',
                      selected: period != null,
                      trailing: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: TextField(
              controller: search,
              onChanged: (_) => onSearch(),
              style: SandolTypography.caption,
              decoration: InputDecoration(
                isDense: true,
                hintText: '강의실을 검색하세요',
                hintStyle: SandolTypography.caption.muted,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: SandolColors.primary,
                  size: 20,
                ),
                contentPadding: EdgeInsets.zero,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: SandolMetrics.radius,
                  borderSide: BorderSide(color: MapColors.line),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: SandolMetrics.radius,
                  borderSide: BorderSide(color: SandolColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 30px 알약 버튼. 고르면 primary 바탕.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.icon,
    this.selected = false,
    this.trailing = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  /// 드롭다운 화살표
  final bool trailing;

  /// 없으면 바깥(PopupMenuButton)이 탭을 받는다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? SandolColors.background : SandolColors.text;
    final pill = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? SandolColors.primary : SandolColors.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: MapColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SandolSpacing.xs,
        children: [
          if (icon != null) Icon(icon, size: 13, color: fg),
          Text(label, style: SandolTypography.caption.copyWith(color: fg)),
          if (trailing)
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: pill,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.size);

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// 건물 한 장: 건물명 · 빈 개수 · 층별 호실 상태 칩 (2538:17489 Frame 2147235306)
class _BuildingRooms extends StatelessWidget {
  const _BuildingRooms({
    required this.building,
    required this.rooms,
    required this.onTap,
  });

  final EmptyClass building;
  final List<(String, RoomStatus)> rooms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final floors = <String, List<(String, RoomStatus)>>{};
    for (final r in rooms) {
      floors.putIfAbsent(floorOf(r.$1), () => []).add(r);
    }
    final sortedFloors =
        floors.keys.toList()..sort((a, b) {
          if (a == '기타') return 1;
          if (b == '기타') return -1;
          return a.compareTo(b);
        });

    return Container(
      decoration: BoxDecoration(
        borderRadius: SandolMetrics.radius,
        border: Border.all(color: MapColors.line),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: SandolMetrics.radius,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    building.className,
                    style: SandolTypography.body.accent,
                  ),
                ),
                Text(
                  '${building.emptyCount}개',
                  style: SandolTypography.headline.accent,
                ),
                const SizedBox(width: SandolSpacing.md),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
          for (final floor in sortedFloors) ...[
            const SizedBox(height: 12),
            Row(
              spacing: SandolSpacing.sm,
              children: [
                SvgPicture.asset(SandolAssets.floor, width: 12),
                Text(floor, style: SandolTypography.caption),
              ],
            ),
            const SizedBox(height: SandolSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final (room, status) in floors[floor]!)
                  _RoomChip(room, status),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip(this.room, this.status);

  final String room;
  final RoomStatus status;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 58),
    height: 51,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: status.fill,
      borderRadius: BorderRadius.circular(10.9),
      border: Border.all(color: MapColors.line),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(room, style: SandolTypography.caption),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(status.dot, 7),
            const SizedBox(width: 2.4),
            Text(
              status.label,
              style: SandolTypography.caption.copyWith(fontSize: 10, height: 1),
            ),
          ],
        ),
      ],
    ),
  );
}
