import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handol/common/component/handol_card.dart';
import 'package:handol/common/component/handol_chip.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/core/utils/keep_all.dart';
import 'package:handol/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handol/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';
import 'package:handol/shared/widget/remote_image.dart';

class HomeMealSection extends ConsumerStatefulWidget {
  final List<RestaurantMenu> menus;
  final VoidCallback? onTap;

  const HomeMealSection({required this.menus, this.onTap, super.key});

  @override
  ConsumerState<HomeMealSection> createState() => _HomeMealSectionState();
}

class _HomeMealSectionState extends ConsumerState<HomeMealSection> {
  late PageController _controller;

  /// provider 변경에 따른 `animateToPage` 진행 중 여부. 이동 중 지나치는 중간
  /// 페이지의 `onPageChanged`가 선택을 되돌려 쓰는 피드백 루프를 막는다.
  bool _animating = false;

  /// 식당 ID → 카드 실측 높이. 드래그 중 높이 보간에 쓴다.
  final Map<int, double> _heights = {};

  /// 식당 ID → 칩 위젯 키. 칩 줄을 카드 위치에 맞출 때 칩 위치를 잰다.
  final Map<int, GlobalKey> _chipKeys = {};

  GlobalKey _chipKey(int restaurantId) =>
      _chipKeys.putIfAbsent(restaurantId, () => GlobalKey());

  final _chipScroll = ScrollController();
  final _chipRowKey = GlobalKey();

  /// 선택된 식당의 menus 내 위치. 선택이 없거나 목록에 없으면 0.
  int _selectedIndex() {
    final id = ref.read(selectedRestaurantIdProvider);
    final i = widget.menus.indexWhere((m) => m.restaurant.id == id);
    return i < 0 ? 0 : i;
  }

  /// 칩 줄을 카드 스크롤 위치(`page`)에 맞춰 매 프레임 민다. 이웃한 두 칩의
  /// 가운데를 page 소수부로 보간해, 카드를 끄는 만큼 칩 줄도 같이 움직인다.
  void _followPage() {
    if (!_controller.hasClients ||
        !_controller.position.haveDimensions ||
        !_chipScroll.hasClients) {
      return;
    }
    final menus = widget.menus;
    final page = _controller.page!;
    final lo = page.floor().clamp(0, menus.length - 1);
    final hi = (lo + 1).clamp(0, menus.length - 1);
    final a = _chipCenter(menus[lo].restaurant.id);
    final b = _chipCenter(menus[hi].restaurant.id);
    if (a == null || b == null) return;
    final center = a + (b - a) * (page - lo).clamp(0.0, 1.0);
    final pos = _chipScroll.position;
    pos.jumpTo(
      (center - pos.viewportDimension / 2).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      ),
    );
  }

  /// 칩 줄(스크롤 내용) 기준 칩 가운데 x. 아직 그려지지 않았으면 null.
  double? _chipCenter(int restaurantId) {
    final chip = _chipKeys[restaurantId]?.currentContext?.findRenderObject();
    final row = _chipRowKey.currentContext?.findRenderObject();
    if (chip is! RenderBox || row is! RenderBox) return null;
    return chip.localToGlobal(Offset(chip.size.width / 2, 0), ancestor: row).dx;
  }

  /// 이웃 카드 사이 간격
  static const double _cardGap = 12;

  /// 카드 영역은 화면 여백 안쪽이지만 PageView는 화면 폭 전체를 쓴다.
  /// PageView가 자기 폭 밖의 페이지는 그리지 않으므로, 한 페이지를
  /// `카드 + 간격`으로 좁혀 이웃 카드가 양옆 여백에 비치게 한다.
  double? _viewportFraction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context).width;
    if (screen <= 0) return;
    final fraction = ((screen - 2 * HandolMetrics.pageGutter + _cardGap) /
            screen)
        .clamp(0.1, 1.0);
    if (fraction == _viewportFraction) return;
    final first = _viewportFraction == null;
    final old = first ? null : _controller;
    _viewportFraction = fraction;
    // 상세 페이지에서 고른 식당 카드에서 바로 시작한다. 화면 폭이 바뀌면
    // 보던 카드에서 다시 시작한다.
    _controller = PageController(
      initialPage:
          old != null && old.hasClients
              ? (old.page ?? 0).round()
              : _selectedIndex(),
      viewportFraction: fraction,
    )..addListener(_followPage);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    // 상세 페이지에서 먼 식당을 고르고 돌아온 경우 첫 프레임에 칩을 맞춘다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _followPage();
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
    _chipScroll.dispose();
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

    // 칩 탭·상세 페이지 등에서 선택이 바뀌면 카드 페이지를 옮긴다.
    // 칩 줄은 카드가 움직이는 동안 _followPage 가 따라 민다.
    ref.listen(selectedRestaurantIdProvider, (previous, next) {
      if (next != null && next != previous) _syncPage(next);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 식당 선택 칩. 칩 위치를 재야 하므로(ListView는 화면 밖 칩을 빌드하지
        // 않는다) 칩 개수가 적은 홈에서는 전부 빌드하는 Row 스크롤을 쓴다.
        SizedBox(
          height: HandolChip.height,
          child: SingleChildScrollView(
            controller: _chipScroll,
            scrollDirection: Axis.horizontal,
            // 섹션은 화면 여백 안에 있지만 칩 줄은 화면 끝까지 흘러간다.
            clipBehavior: Clip.none,
            child: Row(
              key: _chipRowKey,
              spacing: 12,
              children: [
                for (var i = 0; i < menus.length; i++)
                  HandolChip(
                    key: _chipKey(menus[i].restaurant.id),
                    label: menus[i].name,
                    selected: i == selected,
                    onTap: () => _select(i),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: HandolSpacing.sm),

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
          // 섹션 여백 밖으로 화면 끝까지 넓혀, 이웃 카드가 양옆 여백에 비치게 한다.
          child: LayoutBuilder(
            builder:
                (context, c) => OverflowBox(
                  minWidth: c.maxWidth + 2 * HandolMetrics.pageGutter,
                  maxWidth: c.maxWidth + 2 * HandolMetrics.pageGutter,
                  child: ClipRect(
                    // 가로는 화면 끝까지, 세로는 카드 그림자가 잘리지 않게 여유를 둔다.
                    clipper: const _ShadowClipper(),
                    child: _pages(),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _pages() {
    final menus = widget.menus;
    return PageView.builder(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _cardGap / 2),
              child: GestureDetector(
                onTap: () {
                  // 상세 페이지가 동일한 식당으로 진입하도록 선택 ID를 확정한다.
                  _select(index);
                  widget.onTap?.call();
                },
                child: _MealMenuCard(menu: menu),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 가로는 자기 폭(화면 폭) 그대로, 세로는 카드 그림자(offset 4 + blur 4)만큼
/// 위아래로 넓힌 클립 영역.
class _ShadowClipper extends CustomClipper<Rect> {
  const _ShadowClipper();

  static const double _vertical = 12;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -_vertical, size.width, size.height + _vertical);

  @override
  bool shouldReclip(_ShadowClipper oldClipper) => false;
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

    return HandolCard(
      // field(20%)를 배경 위에 합성한 불투명 값. 반투명이면 그림자가 비친다.
      color: HandolColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HandolSpacing.xs,
        children: [
          if (photo != null || photoUrl != null)
            SizedBox(
              height: _photoHeight,
              child: RemoteImage(url: photoUrl, asset: photo),
            ),
          ColoredBox(
            color: HandolColors.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HandolMetrics.cardInset,
                vertical: HandolSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HandolSpacing.sm,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          menu.name.keepAll,
                          style: HandolTypography.caption.strong,
                        ),
                      ),
                      if (price != null)
                        Text(
                          '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}원',
                          style: HandolTypography.caption.strong.accent,
                        ),
                    ],
                  ),
                  // 메뉴는 가운데 정렬 (Figma 2153:244).
                  if (items.isEmpty)
                    // 홈 카드는 늘 오늘 식단이라 날짜 분기는 두지 않는다.
                    Text(
                      '오늘 메뉴가 아직 등록되지 않았어요'.keepAll,
                      textAlign: TextAlign.center,
                      style: HandolTypography.caption.muted,
                    )
                  else
                    for (final item in items)
                      Text(
                        item.keepAll,
                        textAlign: TextAlign.center,
                        style: HandolTypography.caption,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
