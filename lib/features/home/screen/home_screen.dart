import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/refresh_icon_button.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/home/model/banner_model.dart';
import 'package:handori/features/home/presentation/provider/home_static_provider.dart';
import 'package:handori/features/home/component/banner_card_top.dart';
import 'package:handori/features/bus/component/bus_time_card.dart';
import 'package:handori/features/empty_class/component/empty_class_card.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/widget/meal_card.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _SectionHeader extends StatelessWidget {
  final String title;

  /// 제목 오른쪽 끝에 두는 작은 액션 (새로고침 등)
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: AppTextStyles.title02.copyWith(color: Colors.black87),
    );
    if (trailing == null) return text;
    return Row(
      children: [
        Expanded(child: text),
        trailing!,
      ],
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final VoidCallback onTap;
  const _OrganizationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    const subtleBg = AppColors.subtleBg;
    const border = AppColors.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: subtleBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.account_tree_outlined,
                color: primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('학과/부서 조회', style: AppTextStyles.title03),
                  const SizedBox(height: 2),
                  Text(
                    '전체 조직도와 연락처를 확인하세요',
                    style: AppTextStyles.caption03.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Banners> banner = ref.watch(bannersProvider);

    const padding = SizedBox(height: 20);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '산돌이',
        titleWidget: Image.asset(
          'assets/img/sandol_LG.png',
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          // 내용이 화면보다 짧아도 당겨서 새로고침이 되도록
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealSection(),

                const SizedBox(height: 20),

                _SectionHeader(
                  title: '셔틀버스',
                  trailing: RefreshIconButton(
                    onRefresh: () async {
                      ref.read(shuttleClockProvider.notifier).refresh();
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Bustimescreen(
                  onTap: () => StatefulNavigationShell.of(context).goBranch(0),
                  showHeader: false,
                ),

                const SizedBox(height: 20),

                _SectionHeader(title: '빈 강의실'),
                const SizedBox(height: 10),

                EmptyClassTimelineCard(
                  maxItems: 3,
                  onBuildingTap: (name) {
                    // 상세 지도가 열리면 이 건물로 시트를 올린다.
                    ref
                        .read(emptyClassFocusControllerProvider.notifier)
                        .request(name);
                    StatefulNavigationShell.of(context).goBranch(4);
                  },
                ),

                const SizedBox(height: 20),

                _SectionHeader(title: '학과/부서 조직도'),
                const SizedBox(height: 10),

                _OrganizationCard(
                  onTap: () => context.push(RoutePaths.organization),
                ),

                padding,

                BannerTop(images: banner),

                const SizedBox(height: 20),
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
    // 위치는 권한 확인(플랫폼 왕복)이 끝난 뒤 별도로 다시 잡는다. 인디케이터는
    // API 응답까지만 기다리고, 위치 갱신(최대 8초)은 카드가 이전 정렬을 보여준
    // 채 백그라운드로 따라온다.
    final locationRetry = _refreshLocationIfGranted();

    Future<void> settle(Future<Object?> f) => f.then((_) {}, onError: (_) {});
    await Future.wait([
      settle(ref.read(restaurantListNotifierProvider.future)),
      settle(ref.read(mealListNotifierProvider().future)),
      settle(ref.read(emptyClassesProvider.future)),
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
        child: Center(child: SandolLoadingIndicator()),
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '등록된 식당이 없습니다',
          style: AppTextStyles.caption03.copyWith(color: Colors.black45),
        ),
      );
    }

    return HomeMealSection(
      menus: buildRestaurantMenus(restaurants, meals),
      onTap: () => StatefulNavigationShell.of(context).goBranch(1),
    );
  }
}

/// 학식 섹션 에러 뷰 (재시도 포함)
class _MealErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _MealErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '학식 정보를 불러올 수 없습니다.',
              style: AppTextStyles.caption03.copyWith(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
