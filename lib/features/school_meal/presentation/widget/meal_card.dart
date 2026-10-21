import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_chip.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';
import 'package:handori/shared/widget/remote_image.dart';

class HomeMealSection extends ConsumerStatefulWidget {
  final List<RestaurantMenu> menus;
  final VoidCallback? onTap;

  const HomeMealSection({required this.menus, this.onTap, super.key});

  @override
  ConsumerState<HomeMealSection> createState() => _HomeMealSectionState();
}

class _HomeMealSectionState extends ConsumerState<HomeMealSection> {
  late final PageController _controller;

  /// provider 변경에 따른 `animateToPage` 진행 중 여부. 이동 중 지나치는 중간
  /// 페이지의 `onPageChanged`가 선택을 되돌려 쓰는 피드백 루프를 막는다.
  bool _animating = false;

  /// 식당 ID → 카드 실측 높이. 드래그 중 높이 보간에 쓴다.
  final Map<int, double> _heights = {};

  /// 식당 ID → 칩 위젯 키. 선택된 칩이 스크롤 영역 밖에 있을 때
  /// `Scrollable.ensureVisible`로 찾아가기 위해 보관한다.
  final Map<int, GlobalKey> _chipKeys = {};

  GlobalKey _chipKey(int restaurantId) =>
      _chipKeys.putIfAbsent(restaurantId, () => GlobalKey());

  /// 선택된 식당의 menus 내 위치. 선택이 없거나 목록에 없으면 0.
  int _selectedIndex() {
    final id = ref.read(selectedRestaurantIdProvider);
    final i = widget.menus.indexWhere((m) => m.restaurant.id == id);
    return i < 0 ? 0 : i;
  }

  /// 선택된 칩이 칩 목록 스크롤 영역 밖에 있으면 보이는 위치로 스크롤한다.
  void _revealChip(int restaurantId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipContext = _chipKeys[restaurantId]?.currentContext;
      if (chipContext == null || !mounted) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // 상세 페이지에서 고른 식당 카드에서 바로 시작한다.
    _controller = PageController(initialPage: _selectedIndex());
    // 상세 페이지에서 먼 식당을 고르고 돌아온 경우 첫 프레임에 칩을 노출한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ref.read(selectedRestaurantIdProvider);
      if (id != null) _revealChip(id);
    });
  }

  @override
  void didUpdateWidget(HomeMealSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 식당 목록 구성이 바뀌면 선택 식당의 새 위치로 옮긴다.
    final ids = widget.menus.map((m) => m.restaurant.id).toList();
    final oldIds = oldWidget.menus.map((m) => m.restaurant.id).toList();
    if (!listEquals(ids, oldIds)) {
      _heights.removeWhere((id, _) => !ids.contains(id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_selectedIndex());
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 칩 탭·페이지 이동으로 선택이 바뀌면 이 식당을 provider에 반영한다.
  void _select(int index) {
    if (index < 0 || index >= widget.menus.length) return;
    ref
        .read(selectedRestaurantIdProvider.notifier)
        .select(widget.menus[index].restaurant.id);
  }

  /// provider가 바뀌었을 때 컨트롤러를 해당 페이지로 옮긴다. 이미 그 페이지거나
  /// 손가락으로 드래그해 도착한 경우에는 아무것도 하지 않는다.
  Future<void> _syncPage(int? id) async {
    final index = widget.menus.indexWhere((m) => m.restaurant.id == id);
    if (index < 0 || !_controller.hasClients) return;
    if ((_controller.page ?? index.toDouble()).round() == index) return;
    _animating = true;
    try {
      await _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } finally {
      _animating = false;
    }
  }

  void _setHeight(int restaurantId, double height) {
    if (!mounted || _heights[restaurantId] == height) return;
    setState(() => _heights[restaurantId] = height);
  }

  /// 현재 스크롤 위치(`page`)에서 이웃한 두 카드 높이를 선형 보간한 값.
  /// 측정 전이면 null.
  double? _interpolatedHeight() {
    final menus = widget.menus;
    final position = _controller.hasClients ? _controller.position : null;
    final page =
        position != null && position.haveDimensions
            ? _controller.page!
            : _selectedIndex().toDouble();
    final lo = page.floor().clamp(0, menus.length - 1);
    final hi = (lo + 1).clamp(0, menus.length - 1);
    final h1 = _heights[menus[lo].restaurant.id];
    final h2 = _heights[menus[hi].restaurant.id];
    if (h1 == null || h2 == null) return h1 ?? h2;
    return h1 + (h2 - h1) * (page - lo).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final menus = widget.menus;
    if (menus.isEmpty) return const SizedBox.shrink();

    // 선택 상태는 전역 provider(식당 ID)로부터 파생한다. 상세 페이지에서 탭을
    // 바꾸면 ID가 갱신되고, 홈으로 돌아왔을 때 같은 칩이 선택돼 보인다.
    final selectedId = ref.watch(selectedRestaurantIdProvider);
    var selected = menus.indexWhere((m) => m.restaurant.id == selectedId);
    if (selected < 0) selected = 0;

    // 스와이프·상세 페이지 등 어디서 선택이 바뀌어도 해당 칩이 보이게 스크롤하고
    // 카드 페이지도 맞춘다.
    ref.listen(selectedRestaurantIdProvider, (previous, next) {
      if (next != null && next != previous) {
        _revealChip(next);
        _syncPage(next);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 식당 선택 칩. ListView는 화면 밖 칩을 빌드하지 않아 ensureVisible이
        // 불가능하므로, 칩 개수가 적은 홈에서는 전부 빌드하는 Row 스크롤을 쓴다.
        SizedBox(
          height: SandolChip.height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // 섹션은 화면 여백 안에 있지만 칩 줄은 화면 끝까지 흘러간다.
            clipBehavior: Clip.none,
            child: Row(
              spacing: 12,
              children: [
                for (var i = 0; i < menus.length; i++)
                  SandolChip(
                    key: _chipKey(menus[i].restaurant.id),
                    label: menus[i].name,
                    selected: i == selected,
                    onTap: () => _select(i),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SandolSpacing.sm),

        // 식당 메뉴 카드 — PageView가 손가락을 따라 움직이고, 높이는 이웃한
        // 두 카드 높이를 page 값으로 보간한다.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final height = _interpolatedHeight();
            // 측정 전 첫 프레임은 높이 0으로 두고 숨겨 깜빡임을 막는다.
            return Opacity(
              opacity: height == null ? 0 : 1,
              child: SizedBox(height: height ?? 0, child: child),
            );
          },
          child: PageView.builder(
            controller: _controller,
            // 카드 그림자가 잘리지 않게 하고, 이웃 카드 높이를 미리 재도록
            // 양옆 한 화면만큼 미리 빌드한다.
            clipBehavior: Clip.none,
            allowImplicitScrolling: true,
            scrollCacheExtent: const ScrollCacheExtent.viewport(1),
            itemCount: menus.length,
            onPageChanged: (index) {
              if (!_animating) _select(index);
            },
            itemBuilder: (context, index) {
              final menu = menus[index];
              return OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: double.infinity,
                child: _HeightReporter(
                  onHeight: (h) => _setHeight(menu.restaurant.id, h),
                  child: GestureDetector(
                    onTap: () {
                      // 상세 페이지가 동일한 식당으로 진입하도록 선택 ID를 확정한다.
                      _select(index);
                      widget.onTap?.call();
                    },
                    child: _MealMenuCard(menu: menu),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 자식의 레이아웃 높이가 바뀔 때마다 [onHeight]로 알린다(레이아웃 중 setState를
/// 피하려고 다음 프레임에 호출).
class _HeightReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<double> onHeight;

  const _HeightReporter({required this.onHeight, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(h);
    });
  }
}

/// 선택된 식당의 현재(또는 다음) 끼니 메뉴 카드 (Figma 2153:237).
/// 사진이 있는 식당만 머리 사진을 얹는다.
class _MealMenuCard extends StatelessWidget {
  final RestaurantMenu menu;

  const _MealMenuCard({required this.menu});

  static const double _photoHeight = 125;

  @override
  Widget build(BuildContext context) {
    final slot = findCurrentOrNextSlot(menu.slots);
    final price = slot?.price;
    final photo = menu.photoAsset;
    final photoUrl = menu.photoUrlFor(slot);
    final items = slot?.menu ?? const <String>[];

    return SandolCard(
      // field(20%)를 배경 위에 합성한 불투명 값. 반투명이면 그림자가 비친다.
      color: SandolColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SandolSpacing.xs,
        children: [
          if (photo != null || photoUrl != null)
            SizedBox(
              height: _photoHeight,
              child: RemoteImage(url: photoUrl, asset: photo),
            ),
          ColoredBox(
            color: SandolColors.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SandolMetrics.cardInset,
                vertical: SandolSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SandolSpacing.sm,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(menu.name, style: SandolTypography.caption),
                      ),
                      if (price != null)
                        Text(
                          '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}원',
                          style: SandolTypography.caption.accent,
                        ),
                    ],
                  ),
                  if (items.isEmpty)
                    Text('오늘은 운영하지 않아요', style: SandolTypography.caption.muted)
                  else
                    for (final item in items)
                      Text(item, style: SandolTypography.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
