import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/error/app_error_handler.dart';
import 'package:handori/core/router/app_router.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  // .env 는 gitignore 대상이다. pubspec 의 asset 등록 때문에 파일 자체는 빌드에
  // 필요하지만(클린 체크아웃은 `cp .env.example .env`), 비어 있거나 형식이
  // 깨져도 앱은 떠야 한다(지도만 비활성). 로드에 실패하면 빈 환경으로
  // 초기화해 이후 dotenv.env 접근이 NotInitializedError 를 던지지 않게 한다.
  // 키 값은 절대 로그에 남기지 않는다.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env 로드 실패, 환경값 없이 시작합니다: $e');
    dotenv.testLoad(fileInput: '');
  }

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
  /// 시간에 묶인 화면(다음 셔틀, 빈 강의실 조회 구간)도 "지금"으로 맞춘다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authNotifierProvider.notifier).refreshIfNeeded();
        ref.read(shuttleClockProvider.notifier).setAppVisible(true);
        ref.read(classroomQueryControllerProvider.notifier).syncToNow();
      case AppLifecycleState.paused:
        ref.read(shuttleClockProvider.notifier).setAppVisible(false);
      default:
        break;
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
