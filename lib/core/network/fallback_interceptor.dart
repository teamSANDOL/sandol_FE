import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 운영 서버가 못 받는 GET·HEAD 요청을 `.env` 의 API_FALLBACK_BASE_URL 로 1회 재시도한다.
/// 대체 주소가 없으면 아무것도 하지 않는다.
///
/// 재시도 대상은 "서버가 아직 그 요청을 처리할 수 없는" 응답뿐이다: 404(운영에 미배포
/// API), 502·503·504, 연결 실패·타임아웃. 401·403·400·422·500 은 요청 자체나 계정
/// 문제라 다른 서버로 보내도 같은 결과이므로 재시도하지 않는다.
/// 운영 토큰이 다른 서버로 새지 않도록 재시도에는 인증 헤더를 싣지 않고,
/// 멱등하지 않은 쓰기 메서드는 중복 실행을 막기 위해 재시도하지 않는다.
/// 재시도는 인터셉터가 없는 별도 Dio 로 보내므로 무한 반복이 생기지 않는다.
class FallbackInterceptor extends Interceptor {
  final Dio _dio;
  final String? _fallbackBaseUrl;

  /// 재시도 전용 Dio. 인터셉터(인증 포함)는 공유하지 않고 어댑터만 공유한다.
  late final Dio _retryDio = Dio(
    BaseOptions(
      connectTimeout: _dio.options.connectTimeout,
      receiveTimeout: _dio.options.receiveTimeout,
    ),
  )..httpClientAdapter = _dio.httpClientAdapter;

  /// [dio] 는 이 인터셉터가 붙는 Dio. [fallbackBaseUrl] 이 null·빈 값이면 비활성이다.
  FallbackInterceptor(this._dio, {String? fallbackBaseUrl})
    : _fallbackBaseUrl = (fallbackBaseUrl?.isEmpty ?? true)
          ? null
          : fallbackBaseUrl;

  /// `.env` 의 API_FALLBACK_BASE_URL 로 만든다.
  factory FallbackInterceptor.fromEnv(Dio dio) => FallbackInterceptor(
    dio,
    fallbackBaseUrl: dotenv.maybeGet('API_FALLBACK_BASE_URL'),
  );

  static const _retryableStatuses = {404, 502, 503, 504};

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;
    final status = err.response?.statusCode;
    if (status != null) return _retryableStatuses.contains(status);
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_fallbackBaseUrl == null || !_shouldRetry(err)) {
      return handler.next(err);
    }
    try {
      handler.resolve((await retry(err.requestOptions))!);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  /// [original]과 같은 경로·쿼리로 대체 서버에 GET·HEAD 를 1회 보낸다. 대체
  /// 주소가 없으면 null. 인증 헤더는 싣지 않는다.
  ///
  /// 오류 응답이 아니라 200 본문을 해석하지 못한 경우처럼 인터셉터가 볼 수
  /// 없는 실패에서는 호출부가 직접 부른다(지금은 셔틀 시간표만).
  Future<Response<dynamic>?> retry(RequestOptions original) async {
    final base = _fallbackBaseUrl;
    if (base == null) return null;
    final uri = Uri.parse(base).replace(
      path: original.uri.path,
      query: original.uri.hasQuery ? original.uri.query : null,
    );
    if (kDebugMode) {
      debugPrint('[Fallback] ${original.method} ${original.uri.path} -> 대체 서버');
    }
    return _retryDio.requestUri<dynamic>(
      uri,
      options: Options(
        method: original.method,
        responseType: original.responseType,
        // 인증 헤더는 일부러 복사하지 않는다.
        headers: {
          if (original.headers['Accept'] != null)
            'Accept': original.headers['Accept'],
        },
      ),
    );
  }
}
