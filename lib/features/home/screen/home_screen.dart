import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/common/component/app_top_bar.dart';
import 'package:handori/common/component/sandol_bottom_glow.dart';
import 'package:handori/common/component/coming_soon_snackbar.dart';
import 'package:handori/common/component/sandol_section.dart';
import 'package:handori/common/layout/root_shell.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/core/utils/external_link.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/bus/component/bus_time_card.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/empty_class/component/empty_class_card.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_focus_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';
import 'package:handori/features/home/component/organization_quick_card.dart';
import 'package:handori/features/home/component/schedule_section.dart';
import 'package:handori/features/home/model/schedule_event.dart';
import 'package:handori/features/home/presentation/provider/home_static_provider.dart';
import 'package:handori/features/organization/presentation/provider/organization_provider.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/widget/meal_card.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

/// 홈 (Figma 2153:219)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// 빈 주요일정 카드를 X로 닫았는가. 앱을 다시 켜면 다시 보인다.
  bool _emptyScheduleClosed = false;

  void _goBranch(int branch) =>
      StatefulNavigationShell.of(context).goBranch(branch);

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(homeScheduleProvider);
    final schedule = scheduleAsync.valueOrNull;

    return Scaffold(
      backgroundColor: SandolColors.background,
      appBar: AppTopBar(
        title: '산돌이',
        titleWidget: SvgPicture.asset(SandolAssets.logo, semanticsLabel: '산돌이'),
        backgroundColor: SandolColors.background,
        // 로고를 본문 여백(33)에 맞춘다. 뒤로가기 없는 바는 앞에 12를 더 둔다.
        horizontalPadding: SandolMetrics.pageGutter - 12,
      ),
      body: Stack(
        children: [
          const SandolBottomGlow(),
          RefreshIndicator(
            color: SandolColors.primary,
            backgroundColor: SandolColors.background,
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              // 내용이 화면보다 짧아도 당겨서 새로고침이 되도록
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                SandolMetrics.pageGutter,
                SandolSpacing.lg,
                SandolMetrics.pageGutter,
                SandolSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SandolSpacing.xl,
                children: [
                  // 고정 해제 목록을 읽기 전에는 섹션을 비워 둔다.
                  if (scheduleAsync.hasValue &&
                      (schedule != null || !_emptyScheduleClosed))
                    ScheduleSection(
                      event: schedule,
                      today: KoreaTime.now(),
                      onClose: switch (schedule) {
                        final ScheduleEvent event =>
                          () => ref
                              .read(dismissedSchedulesProvider.notifier)
                              .dismiss(event.id),
                        null =>
                          () => setState(() => _emptyScheduleClosed = true),
                      },
                      // 일정 목록 화면이 생기기 전까지 링크 없는 일정은 준비중 안내
                      onDetail: switch (schedule?.url) {
                        final String url =>
                          () => openExternalLink(context, url),
                        null => () => showComingSoonSnackBar(context),
                      },
                    ),
                  SandolSection(title: '학식', child: _buildMealSection()),
                  SandolSection(
                    title: '셔틀버스',
                    child: Bustimescreen(
                      onTap: () => _goBranch(RootShell.busBranch),
                    ),
                  ),
                  SandolSection(
                    title: '빈 강의실',
                    trailing: IconButton(
                      tooltip: '정렬 설정',
                      visualDensity: VisualDensity.compact,
                      icon: SvgPicture.asset(
                        'assets/icon/emptyclass_setting.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          SandolColors.muted,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () => showBuildingSortSheet(context),
                    ),
                    child: EmptyClassTimelineCard(
                      maxItems: 3,
                      onBuildingTap: (name) {
                        // 상세 지도가 열리면 이 건물로 시트를 올린다.
                        ref
                            .read(emptyClassFocusControllerProvider.notifier)
                            .request(name);
                        _goBranch(RootShell.emptyClassBranch);
                      },
                    ),
                  ),
                  SandolSection(
                    title: '학과/부서 조회',
                    child: OrganizationQuickCard(
                      onOpenAll: () => context.push(RoutePaths.organization),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 당겨서 새로고침: 홈의 모든 섹션을 다시 불러온다.
  /// 어느 하나가 실패해도 인디케이터는 정상적으로 내려간다.
  Future<void> _refreshAll() async {
    ref.read(classroomQueryControllerProvider.notifier).syncToNow();
    ref.invalidate(homeScheduleProvider);
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
        padding: const EdgeInsets.symmetric(vertical: SandolSpacing.lg),
        child: Text('등록된 식당이 없습니다', style: SandolTypography.caption.muted),
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
            '학식 정보를 불러올 수 없습니다.',
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
