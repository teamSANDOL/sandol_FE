import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/router/app_router.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // 네이버 지도 SDK 초기화. 키가 비어 있으면 지도 타일만 안 뜨고 앱은 정상 동작한다.
  final naverMapClientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
  if (naverMapClientId.isNotEmpty) {
    await FlutterNaverMap().init(
      clientId: naverMapClientId,
      onAuthFailed: (ex) => debugPrint('네이버 지도 인증 실패: $ex'),
    );
  } else {
    debugPrint('NAVER_MAP_CLIENT_ID 가 .env 에 없습니다. 지도가 표시되지 않습니다.');
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 백그라운드에 오래 있다 돌아오면 액세스 토큰이 만료돼 있기 쉽다.
  /// 첫 API 요청이 리프레시를 기다리지 않도록 복귀 시점에 미리 갱신한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authNotifierProvider.notifier).refreshIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
          displayMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          // w300은 이제 실제 Light로 렌더되어 본문에는 너무 얇다.
          // 디자인 시스템의 본문 굵기(Regular 400)에 맞춘다.
          bodySmall: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.black,
            fontSize: 16,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Krub',
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
