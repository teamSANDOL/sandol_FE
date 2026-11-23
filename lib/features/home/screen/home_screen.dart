import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handol/common/component/app_top_bar.dart';
import 'package:handol/common/component/handol_scroll_gradient.dart';
import 'package:handol/common/component/handol_section.dart';
import 'package:handol/common/layout/root_shell.dart';
import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/core/router/route_paths.dart';
import 'package:handol/core/utils/keep_all.dart';
import 'package:handol/features/bus/component/bus_time_card.dart';
import 'package:handol/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handol/features/empty_class/component/empty_class_card.dart';
import 'package:handol/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handol/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handol/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handol/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handol/features/home/component/organization_quick_card.dart';
import 'package:handol/features/home/component/home_banner_carousel.dart';
import 'package:handol/features/home/data/home_banners.dart';
import 'package:handol/features/organization/presentation/provider/organization_provider.dart';
import 'package:handol/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handol/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handol/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handol/features/school_meal/presentation/widget/meal_card.dart';
import 'package:handol/shared/widget/handol_loading_indicator.dart';

/// 홈 (Figma 홈_re 2890:2393)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// 배경 그라데이션을 스크롤 내용과 함께 움직이기 위해 쓴다.
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goBranch(int branch) =>
      StatefulNavigationShell.of(context).goBranch(branch);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HandolColors.background,
      appBar: AppTopBar(
        title: '한돌이',
        titleWidget: SvgPicture.asset(HandolAssets.logo, semanticsLabel: '한돌이'),
        backgroundColor: HandolColors.background,
        // 로고를 본문 여백(33)에 맞춘다. 뒤로가기 없는 바는 앞에 12를 더 둔다.
        horizontalPadding: HandolMetrics.pageGutter - 12,
      ),
      // 시안 2890:2393 은 프레임이 스크롤 전체(1900)라 배경도 내용 전체에 번진다.
      body: HandolScrollGradient(
        controller: _scroll,
        child: RefreshIndicator(
          color: HandolColors.primary,
          backgroundColor: HandolColors.background,
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            controller: _scroll,
            // 내용이 화면보다 짧아도 당겨서 새로고침이 되도록
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              HandolMetrics.pageGutter,
              HandolSpacing.lg,
              HandolMetrics.pageGutter,
              HandolSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: HandolSpacing.xl,
              children: [
                const HomeBannerCarousel(banners: homeBanners),
                HandolSection(title: '학식', child: _buildMealSection()),
                HandolSection(
                  title: '셔틀버스',
                  child: Bustimescreen(
                    onTap: () => _goBranch(RootShell.busBranch),
                  ),
                ),
                HandolSection(
                  title: '빈 강의실',
                  trailing: IconButton(
                    tooltip: '정렬 설정',
                    visualDensity: VisualDensity.compact,
                    icon: SvgPicture.asset(
                      'assets/icon/emptyclass_setting.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        HandolColors.muted,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => showBuildingSortSheet(context),
                  ),
                  child: EmptyClassTimelineCard(
                    maxItems: 3,
                    onBuildingTap: (name) {
                      // 맵 탭이 열리면 이 건물의 빈 강의실 현황을 띄운다.
                      ref
                          .read(emptyClassFocusControllerProvider.notifier)
                          .request(name);
                      _goBranch(RootShell.mapBranch);
                    },
                  ),
                ),
                HandolSection(
                  title: '학과/부서 조회',
                  child: OrganizationQuickCard(
                    onOpenAll: () => context.push(RoutePaths.organization),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 당겨서 새로고침: 홈의 모든 섹션을 다시 불러온다.
  /// 어느 하나가 실패해도 인디케이터는 정상적으로 내려간다.
  Future<void> _refreshAll() async {
    ref.read(classroomQueryControllerProvider.notifier).syncToNow();
    ref.invalidate(restaurantListNotifierProvider);
    ref.invalidate(mealListNotifierProvider);
    ref.read(shuttleClockProvider.notifier).refresh();
    ref.invalidate(emptyClassesProvider);
    ref.invalidate(organizationTreeNotifierProvider);
    // 위치는 권한 확인(플랫폼 왕복)이 끝난 뒤 별도로 다시 잡는다. 인디케이터는
    // API 응답까지만 기다리고, 위치 갱신(최대 8초)은 카드가 이전 정렬을 보여준
    // 채 백그라운드로 따라온다.
    final locationRetry = _refreshLocationIfGranted();

    Future<void> settle(Future<Object?> f) => f.then((_) {}, onError: (_) {});
    await Future.wait([
      settle(ref.read(restaurantListNotifierProvider.future)),
      settle(ref.read(mealListNotifierProvider().future)),
      settle(ref.read(emptyClassesProvider.future)),
      settle(ref.read(pinnedOrganizationUnitsProvider.future)),
      settle(locationRetry),
    ]);
  }

  /// 위치 서비스가 켜져 있고 영구 거부가 아니면 위치를 다시 잡는다. 허용된
  /// 사용자는 집에서 켠 뒤 학교에 와서 당겼을 때 거리순이 새 위치를 따라가야
  /// 하므로 이미 위치가 있어도 다시 잡고, 영구 거부한 사용자에게는 당길 때마다
  /// 권한 창을 띄우지 않는다.
  Future<void> _refreshLocationIfGranted() async {
    if (await canRetryLocation()) {
      ref.invalidate(userLocationProvider);
    }
  }

  /// 학식 섹션 — 식당 목록 + 오늘 최신 식사를 결합해 표시.
  Widget _buildMealSection() {
    final restaurantsAsync = ref.watch(restaurantListNotifierProvider);
    final mealsAsync = ref.watch(mealListNotifierProvider());

    if (restaurantsAsync.isLoading || mealsAsync.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: HandolLoadingIndicator()),
      );
    }
    if (restaurantsAsync.hasError || mealsAsync.hasError) {
      return _MealErrorView(
        onRetry: () {
          ref.invalidate(restaurantListNotifierProvider);
          ref.invalidate(mealListNotifierProvider());
        },
      );
    }

    final restaurants = restaurantsAsync.value ?? const [];
    final meals = mealsAsync.value ?? const [];
    if (restaurants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: HandolSpacing.lg),
        child: Text(
          '등록된 식당이 없습니다'.keepAll,
          style: HandolTypography.caption.muted,
        ),
      );
    }

    return HomeMealSection(
      menus: buildRestaurantMenus(restaurants, meals),
      onTap: () => _goBranch(RootShell.mealBranch),
    );
  }
}

/// 학식 섹션 에러 뷰 (재시도 포함)
class _MealErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _MealErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '학식 정보를 불러올 수 없습니다.'.keepAll,
            style: HandolTypography.caption.muted,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text('다시 시도', style: HandolTypography.caption.accent),
        ),
      ],
    );
  }
}
