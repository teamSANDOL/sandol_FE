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
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';
import 'package:handori/shared/widget/error_retry_view.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 학식 탭 (Figma 2158:714).
///
/// 식당 칩 → 식당명·날짜·위치 → 끼니별(조식·점심·저녁) 메뉴 카드.
/// 선택 식당은 홈 칩과 같은 [selectedRestaurantIdProvider]를 공유한다.
class RestaurantDetailPage extends ConsumerWidget {
  const RestaurantDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          restaurantsAsync.when(
            data: (restaurants) => _Content(restaurants: restaurants),
            loading:
                () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: SandolLoadingIndicator()),
                ),
            error:
                (e, _) => ErrorRetryView(
                  title: '식당 정보를 불러올 수 없습니다.',
                  onRetry: () => ref.invalidate(restaurantListNotifierProvider),
                ),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (restaurants.isEmpty) {
      return const _Notice('등록된 식당이 없습니다');
    }

    // 선택 탭은 전역 provider(식당 ID)에서 파생한다. 홈 화면의 칩 선택이
    // 그대로 진입 탭으로 반영되고, 여기서 탭을 바꾸면 홈 칩도 동기화된다.
    final selectedId = ref.watch(selectedRestaurantIdProvider);
    var selected = restaurants.indexWhere((r) => r.id == selectedId);
    if (selected < 0) selected = 0;

    final mealsAsync = ref.watch(mealListNotifierProvider());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SandolMetrics.pageGutter,
        SandolSpacing.md,
        SandolMetrics.pageGutter,
        SandolSpacing.xl,
      ),
      children: [
        // 칩 줄은 화면 끝까지 흘러간다(홈과 같은 규칙).
        SizedBox(
          height: SandolChip.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: restaurants.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder:
                (_, i) => SandolChip(
                  label: restaurants[i].name,
                  selected: i == selected,
                  style: SandolChipStyle.solid,
                  onTap:
                      () => ref
                          .read(selectedRestaurantIdProvider.notifier)
                          .select(restaurants[i].id),
                ),
          ),
        ),
        const SizedBox(height: 12),
        mealsAsync.when(
          data:
              (meals) => _MenuSection(
                menu: buildRestaurantMenus(restaurants, meals)[selected],
              ),
          loading:
              () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: SandolLoadingIndicator()),
              ),
          error:
              (e, _) => ErrorRetryView(
                title: '식단 정보를 불러올 수 없습니다.',
                onRetry: () => ref.invalidate(mealListNotifierProvider()),
              ),
        ),
      ],
    );
  }
}

// ── 식당명 · 날짜 · 위치 + 끼니별 블록 ───────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.menu});

  final RestaurantMenu menu;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// `9월 15일 화요일`
  static String _koreanDate(DateTime d) =>
      '${d.month}월 ${d.day}일 ${_weekdays[d.weekday - 1]}요일';

  @override
  Widget build(BuildContext context) {
    final location = menu.location;
    final muted = SandolTypography.caption.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(menu.name, style: SandolTypography.title),
        const SizedBox(height: SandolSpacing.xs),
        Row(
          spacing: SandolSpacing.sm,
          children: [
            Text(_koreanDate(KoreaTime.now()), style: muted),
            if (location != null) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: SandolColors.muted,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 4),
              ),
              Flexible(
                child: SandolIconLabel(
                  icon: SvgPicture.asset(SandolAssets.mealPin),
                  label: location,
                  style: muted,
                  gap: SandolSpacing.xs,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        if (menu.slots.isEmpty)
          const _Notice('오늘은 등록된 식단이 없어요')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 48,
            children: [for (final slot in menu.slots) _MealBlock(slot: slot)],
          ),
      ],
    );
  }
}

/// 끼니 아이콘 + 라벨, 그 아래 메뉴 카드 (2158:748)
class _MealBlock extends StatelessWidget {
  const _MealBlock({required this.slot});

  final MenuSlot slot;

  static String _iconOf(MealType type) => switch (type) {
    MealType.breakfast || MealType.brunch => SandolAssets.mealBreakfast,
    MealType.lunch => SandolAssets.mealLunch,
    MealType.dinner => SandolAssets.mealDinner,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: SandolSpacing.sm,
    children: [
      SandolIconLabel(
        icon: SizedBox.square(
          dimension: SandolMetrics.iconSize,
          child: Center(child: SvgPicture.asset(_iconOf(slot.mealType))),
        ),
        label: slot.label,
        style: SandolTypography.body.strong,
      ),
      _MenuCard(items: slot.menu),
    ],
  );
}

/// 메뉴를 두 열의 불릿 목록으로. 비어 있으면 안내 한 줄.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SandolCard(
        padding: const EdgeInsets.symmetric(
          horizontal: SandolMetrics.cardInset,
          vertical: 14,
        ),
        child: Text('아직 등록된 메뉴가 없어요', style: SandolTypography.caption.muted),
      );
    }
    // 왼쪽 열에 앞 절반, 오른쪽 열에 뒤 절반.
    final half = (items.length + 1) ~/ 2;
    return SandolCard(
      padding: const EdgeInsets.fromLTRB(30, 22, 30, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _BulletColumn(items.sublist(0, half))),
          const SizedBox(width: SandolSpacing.md),
          Expanded(child: _BulletColumn(items.sublist(half))),
        ],
      ),
    );
  }
}

class _BulletColumn extends StatelessWidget {
  const _BulletColumn(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 20,
    children: [
      for (final item in items)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SandolSpacing.sm,
          children: [
            const Text('•', style: SandolTypography.caption),
            Expanded(child: Text(item, style: SandolTypography.caption)),
          ],
        ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: SandolTypography.caption.muted,
    ),
  );
}
