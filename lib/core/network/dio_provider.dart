import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/constants/api_constants.dart';
import 'package:handori/core/network/auth_interceptor.dart';
import 'package:handori/core/network/fallback_interceptor.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      // .env 의 API_BASE_URL 로 오버라이드 가능 (테스트 서버용). 기본은 프로덕션.
      baseUrl: dotenv.maybeGet('API_BASE_URL') ?? ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      () => ref.read(authRepositoryProvider).getValidAccessToken(),
    ),
    FallbackInterceptor.fromEnv(dio),
    // TODO: ErrorInterceptor() — 에러 변환 추가
    if (kDebugMode)
      LogInterceptor(
        requestHeader: false, // Authorization 토큰이 로그에 남지 않게 한다
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
  ]);

  return dio;
}
