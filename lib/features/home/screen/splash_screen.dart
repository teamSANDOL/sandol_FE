import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/empty_class_provider.dart';
import 'package:handori/features/home/presentation/provider/home_static_provider.dart';
import 'package:handori/features/organization/presentation/provider/organization_provider.dart';
import 'package:handori/features/school_meal/presentation/provider/meal_list_notifier.dart';
import 'package:handori/features/school_meal/presentation/provider/restaurant_list_notifier.dart';

class Splashscreen extends ConsumerStatefulWidget {
  const Splashscreen({super.key});
  @override
  ConsumerState<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends ConsumerState<Splashscreen> {
  /// 네트워크가 느려도 스플래시에 갇히지 않게 하는 선로딩 대기 상한.
  /// 넘기면 홈으로 가고, 남은 데이터는 홈의 로딩 표시로 이어진다.
  static const _preloadLimit = Duration(seconds: 5);

  /// 홈 첫 화면이 쓰는 네트워크 데이터. 위치(빈 강의실 거리순)는 권한 창이
  /// 스플래시 위에 뜨지 않도록 홈에서 받는다. 셔틀은 내장 시간표라 제외.
  List<ProviderListenable<Future<Object?>>> get _homeData => [
    homeScheduleProvider.future,
    restaurantListNotifierProvider.future,
    mealListNotifierProvider().future,
    emptyClassesProvider.future,
    pinnedOrganizationUnitsProvider.future,
  ];

  /// autoDispose provider 들이 홈이 구독하기 전에 버려지지 않게 붙잡아 둔다.
  /// 스플래시가 사라질 때는 홈이 이미 같은 provider 를 구독하고 있다.
  final _subscriptions = <ProviderSubscription<Future<Object?>>>[];

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.close();
    }
    super.dispose();
  }

  /// 세션을 복원하고, 로그인 상태면 홈 데이터까지 받은 뒤 넘어간다.
  Future<void> _navigateNext() async {
    final session = await ref
        .read(authNotifierProvider.future)
        .then<AuthSession?>(
          (session) => session,
          onError: (Object error) {
            debugPrint('세션 복원 실패, 로그인 화면으로 이동: $error');
            return null;
          },
        );
    if (session != null && mounted) await _preloadHome();
    if (!mounted) return;
    context.go(session != null ? RoutePaths.home : RoutePaths.login);
  }

  /// 실패한 섹션은 홈에서 각자 오류·재시도를 보여 주므로 여기선 기다리기만 한다.
  Future<void> _preloadHome() async {
    for (final p in _homeData) {
      _subscriptions.add(ref.listenManual(p, (_, _) {}));
    }
    await Future.wait(
      _subscriptions.map((s) => s.read().then((_) {}, onError: (_) {})),
    ).timeout(_preloadLimit, onTimeout: () => const []);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: SandolColors.background,
      body: Center(
        // Figma의 412×733 원본 자산. 세로 중앙 정렬과 종횡비를 유지한다.
        child: Image.asset(
          SandolAssets.splashPoster,
          width: MediaQuery.sizeOf(context).width,
          fit: BoxFit.contain,
          semanticLabel: '산돌이 시작 화면',
        ),
      ),
    ),
  );
}
