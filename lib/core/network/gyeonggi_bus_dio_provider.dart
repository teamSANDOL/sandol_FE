import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/constants/api_constants.dart';

part 'gyeonggi_bus_dio_provider.g.dart';

/// 경기도 버스도착정보(공공데이터포털) 전용 Dio.
/// baseUrl은 host만 지정하고 경로/`serviceKey`는 호출부에서 주입한다.
@Riverpod(keepAlive: true)
Dio gyeonggiBusDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.gyeonggiBusBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.addAll([
    if (kDebugMode)
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
  ]);

  return dio;
}
