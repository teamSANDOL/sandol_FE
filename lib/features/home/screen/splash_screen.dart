import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/shared/widget/sandol_loading_indicator.dart';

class Splashscreen extends ConsumerStatefulWidget {
  const Splashscreen({super.key});

  @override
  ConsumerState<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends ConsumerState<Splashscreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // 배경 이미지가 화면을 덮은 채 살짝 줌아웃되는 효과 (가장자리 노출 없음)
    _scale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _navigateNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    // 스플래시 비트맵(배경 + 캐릭터, 디코드 후 수 MB)은 이 화면에서만 쓴다.
    // 첫 화면이라 캐시에 다른 이미지는 아직 없으므로 통째로 비워도 된다.
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  /// 페이지 전환: 이미 로그인돼 있으면 홈, 아니면 로그인 화면으로.
  /// (로그인 화면에서 "로그인 없이 둘러보기"로 건너뛸 수 있다.)
  ///
  /// 세션 복원(보안 저장소 읽기 + 필요 시 토큰 갱신)은 2초 스플래시와
  /// 병렬로 시작해 둘 중 늦은 쪽이 끝나면 넘어간다. 복원이 어떤 이유로든
  /// 실패하면 비로그인으로 간주하고 로그인 화면으로 보낸다. 여기서 예외가
  /// 새면 화면 전환이 영영 일어나지 않는다.
  Future<void> _navigateNext() async {
    final minimumDisplay = Future<void>.delayed(const Duration(seconds: 2));
    final session = await ref.read(authNotifierProvider.future).then<AuthSession?>(
      (s) => s,
      onError: (Object e) {
        debugPrint('세션 복원 실패, 로그인 화면으로 이동: $e');
        return null;
      },
    );
    await minimumDisplay;
    if (!mounted) return;
    context.go(session != null ? RoutePaths.home : RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 맞춰 디코드해 원본 해상도(배경 1242×2223, 캐릭터 900²)를
    // 통째로 메모리에 올리지 않는다.
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final bgCacheHeight = (size.height * dpr).round();
    final characterCacheWidth = (size.width * 0.72 * dpr).round();
    return Scaffold(
      /// 배경 이미지(bg_splash.jpg)와 같은 밝은 톤 — 페이드인 중 색 튐 방지
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 전체 화면 스플래시: 상하 여백 없이 꽉 채움 (화면이 이미지보다
          // 길쭉한 기기에서는 좌우가 약간 잘린다). 페이드인 + 줌아웃.
          FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/img/bg_splash.jpg',
                fit: BoxFit.cover,
                cacheHeight: bgCacheHeight,
              ),
            ),
          ),

          // 중앙 캐릭터 — 배경(bg_splash.jpg)은 캐릭터가 지워진 상태이고,
          // 투명 PNG 캐릭터를 옛 캐릭터 자리(화면 정중앙)에 올린다.
          FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Image.asset(
                    'assets/img/sandol_kkk.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: characterCacheWidth,
                  ),
                ),
              ),
            ),
          ),

          // 하단: 로딩 애니메이션 + 산돌이 로고
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SandolLoadingIndicator(size: 56),
                      const SizedBox(height: 48),
                      Image.asset('assets/img/sandol_LG.png', width: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

