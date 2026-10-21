import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/sandol_card.dart';
import 'package:handori/common/component/sandol_chip.dart';
import 'package:handori/common/component/sandol_icon_label.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/core/utils/keep_all.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';
import 'package:handori/shared/widget/remote_image.dart';

/// 학식 탭 (Figma 학식-2).
///
/// 요일 스트립(이번 주 월~일) → 끼니 탭(조식·점심·저녁) → 그 끼니를 내는
/// 식당 카드. 카드는 사진·이름·가격과 메뉴를 보여 준다.
class RestaurantDetailPage extends ConsumerStatefulWidget {
  const RestaurantDetailPage({super.key});

  @override
  ConsumerState<RestaurantDetailPage> createState() =>
      _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  late final DateTime _today = _dateOnly(KoreaTime.now());
  late DateTime _date = _today;
  late MealType _mealType = _nowMealType();

  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// 지금(KST) 어느 끼니인지. 기준 시각은 `restaurant_menu.dart`의 노출 우선순위와 같다.
  static MealType _nowMealType() {
    final now = KoreaTime.now();
    final minutes = now.hour * 60 + now.minute;
    if (minutes < 10 * 60 + 30) return MealType.breakfast;
    if (minutes < 18 * 60) return MealType.lunch;
    return MealType.dinner;
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantListNotifierProvider);

    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '학식',
        titleWidget: const Text('학식', style: SandolTypography.title),
        backIcon: SvgPicture.asset(SandolAssets.backArrow),
        onBack:
            () => StatefulNavigationShell.of(
              context,
            ).goBranch(RootShell.homeBranch),
        backgroundColor: SandolColors.background,
        // 뒤로가기 버튼(44) 안의 아이콘(24)이 본문 여백(33)에 맞게
        horizontalPadding: SandolMetrics.pageGutter - 10,
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          ListView(
            padding: const EdgeInsets.fromLTRB(
              SandolMetrics.pageGutter,
              SandolSpacing.md,
              SandolMetrics.pageGutter,
              SandolSpacing.xl,
            ),
            children: [
              _DateStrip(
                today: _today,
                selected: _date,
                onSelect: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 18),
              _MealTabs(
                selected: _mealType,
                nowType: _date == _today ? _nowMealType() : null,
                onSelect: (t) => setState(() => _mealType = t),
              ),
              const SizedBox(height: 20),
              restaurantsAsync.when(
                data:
                    (restaurants) => _Cards(
                      restaurants: restaurants,
                      mealType: _mealType,
                      // 오늘은 date 없이 두면 notifier 가 오늘(KST)로 해석한다.
                      date:
                          _date == _today ? null : DateFormatter.isoDate(_date),
                    ),
                loading:
                    () => const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: SandolLoadingIndicator()),
                    ),
                error:
                    (e, _) => ErrorRetryView(
                      title: '식당 정보를 불러올 수 없습니다.',
                      onRetry:
                          () => ref.invalidate(restaurantListNotifierProvider),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 요일 스트립 · 끼니 탭 ────────────────────────────────────────────────────

/// 선택 여부만 다른 둥근 칸. 선택은 primary 바탕, 아니면 테두리.
///
/// [width]·[height]는 최소 크기다. 글꼴이 커지면 세로로 늘어나고, 가로는 한 줄에
/// 놓인 칸 수만큼 쓸 수 있는 폭이 정해져 있어 넘치면 내용을 줄여 맞춘다.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.width,
    required this.height,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? SandolColors.primary : SandolColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: SandolMetrics.radius,
      side:
          selected
              ? BorderSide.none
              : const BorderSide(color: SandolColors.border),
    ),
    child: InkWell(
      borderRadius: SandolMetrics.radius,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width, minHeight: height),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          // 글꼴 배율은 그대로 따르되 칸 폭을 넘으면 내용을 줄여 맞춘다.
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
        ),
      ),
    ),
  );
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 4,
      children: [
        for (var i = 0; i < 7; i++)
          Flexible(
            child: _dayPill(monday.add(Duration(days: i)), _weekdays[i]),
          ),
      ],
    );
  }

  Widget _dayPill(DateTime day, String weekday) {
    final isSelected = day == selected;
    return _Pill(
      width: 44,
      height: 50,
      selected: isSelected,
      onTap: () => onSelect(day),
      child: Text(
        '$weekday\n${day.month}/${day.day}',
        textAlign: TextAlign.center,
        style:
            isSelected
                ? SandolTypography.caption.strong.onPrimary
                : SandolTypography.caption.copyWith(
                  color: SandolColors.textSecondary,
                ),
      ),
    );
  }
}

class _MealTabs extends StatelessWidget {
  const _MealTabs({
    required this.selected,
    required this.nowType,
    required this.onSelect,
  });

  final MealType selected;

  /// 선택한 날짜가 오늘일 때 지금 끼니. 그 탭에 `• NOW`를 붙인다.
  final MealType? nowType;
  final ValueChanged<MealType> onSelect;

  static const _tabs = [MealType.breakfast, MealType.lunch, MealType.dinner];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    spacing: 4,
    children: [
      for (final type in _tabs)
        Flexible(
          child: _Pill(
            width: SandolChip.minWidth,
            height: SandolChip.height,
            selected: type == selected,
            onTap: () => onSelect(type),
            child: Text(
              type == nowType ? '${type.label} • NOW' : type.label,
              maxLines: 1,
              style:
                  type == selected
                      ? SandolTypography.caption.onPrimary
                      : SandolTypography.caption,
            ),
          ),
        ),
    ],
  );
}

// ── 끼니 헤더 + 식당 카드 ────────────────────────────────────────────────────

class _Cards extends ConsumerWidget {
  const _Cards({
    required this.restaurants,
    required this.mealType,
    required this.date,
  });

  final List<Restaurant> restaurants;
  final MealType mealType;
  final String? date;

  static String _iconOf(MealType type) => switch (type) {
    MealType.breakfast || MealType.brunch => SandolAssets.mealBreakfast,
    MealType.lunch => SandolAssets.mealLunch,
    MealType.dinner => SandolAssets.mealDinner,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealListNotifierProvider(date: date));
    return mealsAsync.when(
      data: (meals) {
        // 이 끼니에 메뉴가 등록된 식당만 보여 준다.
        final cards = <(RestaurantMenu, MenuSlot)>[];
        for (final menu in buildRestaurantMenus(restaurants, meals)) {
          for (final slot in menu.slots) {
            if (slot.mealType == mealType && slot.menu.isNotEmpty) {
              cards.add((menu, slot));
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // 큰 글꼴에서는 '식당 N곳'이 아래 줄로 내려가게 Wrap 으로 둔다.
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: SandolSpacing.md,
                    children: [
                      SandolIconLabel(
                        icon: SizedBox.square(
                          dimension: SandolMetrics.iconSize,
                          child: Center(
                            child: SvgPicture.asset(_iconOf(mealType)),
                          ),
                        ),
                        label: mealType.label,
                        style: SandolTypography.title.accent,
                      ),
                      Text(
                        '식당 ${cards.length}곳',
                        style: SandolTypography.caption.copyWith(
                          color: SandolColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ponytail: 서버에 좋아요·인기 데이터가 없어 정렬은 동작하지 않는다(표시만).
                Text(
                  '인기순',
                  style: SandolTypography.caption.strong.copyWith(
                    color: SandolColors.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: SandolColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (cards.isEmpty)
              const _Notice('등록된 식단이 없어요')
            else
              Column(
                spacing: 20,
                children: [
                  for (final (menu, slot) in cards)
                    _RestaurantCard(menu: menu, slot: slot),
                ],
              ),
          ],
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: SandolLoadingIndicator()),
          ),
      error:
          (e, _) => ErrorRetryView(
            title: '식단 정보를 불러올 수 없습니다.',
            onRetry: () => ref.invalidate(mealListNotifierProvider(date: date)),
          ),
    );
  }
}

/// 위: 사진 + 이름·가격 + 좋아요, 구분선, 아래: 메뉴 목록.
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.menu, required this.slot});

  final RestaurantMenu menu;
  final MenuSlot slot;

  /// 7000 → `7,000원`
  static String _won(int price) =>
      '${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',')}원';

  @override
  Widget build(BuildContext context) {
    final photo = menu.photoAsset;
    final price = slot.price;
    return SandolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(SandolMetrics.cardInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: SandolMetrics.radius,
                  child: SizedBox(
                    width: 102,
                    height: 89,
                    child: RemoteImage(
                      url: menu.photoUrlFor(slot),
                      asset: photo,
                    ),
                  ),
                ),
                const SizedBox(width: SandolSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu.name.keepAll, style: SandolTypography.headline),
                      if (price != null)
                        Text(_won(price), style: SandolTypography.body.accent),
                    ],
                  ),
                ),
                // ponytail: 좋아요 수 API가 없어 아이콘만 둔다. 서버 지원 시 숫자·토글 연결.
                const Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: SandolColors.inactive,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: SandolColors.border),
          Padding(
            padding: const EdgeInsets.all(SandolMetrics.cardInset),
            child: Wrap(
              spacing: SandolSpacing.lg,
              runSpacing: SandolSpacing.md,
              children: [
                for (final item in slot.menu)
                  Text(item.keepAll, style: SandolTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Text(
      message.keepAll,
      textAlign: TextAlign.center,
      style: SandolTypography.caption.muted,
    ),
  );
}
