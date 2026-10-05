import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';

class Splashscreen extends ConsumerStatefulWidget {
  const Splashscreen({super.key});
  @override
  ConsumerState<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends ConsumerState<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  /// 세션 복원과 최소 표시 시간을 병렬로 유지한다.
  Future<void> _navigateNext() async {
    final minimumDisplay = Future<void>.delayed(const Duration(seconds: 2));
    final session = await ref
        .read(authNotifierProvider.future)
        .then<AuthSession?>(
          (session) => session,
          onError: (Object error) {
            debugPrint('세션 복원 실패, 로그인 화면으로 이동: $error');
            return null;
          },
        );
    await minimumDisplay;
    if (!mounted) return;
    context.go(session != null ? RoutePaths.home : RoutePaths.login);
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
