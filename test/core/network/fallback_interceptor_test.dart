import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/network/fallback_interceptor.dart';

/// 호스트별로 정해진 상태코드를 돌려주고 받은 요청을 기록하는 어댑터.
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, int> statusByHost;
  final requests = <RequestOptions>[];

  _FakeAdapter(this.statusByHost);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'host': options.uri.host}),
      statusByHost[options.uri.host] ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _build(_FakeAdapter adapter, {String? fallback}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://prod.example.com'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    // AuthInterceptor 역할: 운영 요청에 토큰 헤더를 싣는다.
    InterceptorsWrapper(
      onRequest: (o, h) {
        o.headers['Authorization'] = 'Bearer secret';
        o.headers['X-User-ID'] = 'u1';
        h.next(o);
      },
    ),
    FallbackInterceptor(dio, fallbackBaseUrl: fallback),
  ]);
  return dio;
}

void main() {
  const fallback = 'https://test.example.com';

  test('404 이면 대체 주소로 같은 경로·쿼리를 1회 재시도하고 결과를 반환', () async {
    final adapter = _FakeAdapter({'prod.example.com': 404});
    final res = await _build(
      adapter,
      fallback: fallback,
    ).get<dynamic>('/static-info/tuk-world/restaurants?x=1');

    expect(res.statusCode, 200);
    expect(adapter.requests.length, 2);
    final retry = adapter.requests.last;
    expect(
      retry.uri.toString(),
      'https://test.example.com/static-info/tuk-world/restaurants?x=1',
    );
    expect(retry.method, 'GET');
  });

  test('재시도 요청에는 Authorization·X-User-ID 가 없다', () async {
    final adapter = _FakeAdapter({'prod.example.com': 503});
    await _build(adapter, fallback: fallback).get<dynamic>('/a');

    final headers = adapter.requests.last.headers.keys.map(
      (k) => k.toLowerCase(),
    );
    expect(headers, isNot(contains('authorization')));
    expect(headers, isNot(contains('x-user-id')));
  });

  test('대체 주소도 실패하면 그 오류를 반환하고 더 재시도하지 않는다', () async {
    final adapter = _FakeAdapter({
      'prod.example.com': 404,
      'test.example.com': 404,
    });
    await expectLater(
      _build(adapter, fallback: fallback).get<dynamic>('/a'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.length, 2);
  });

  for (final status in [400, 401, 403, 422, 500]) {
    test('$status 는 재시도하지 않는다', () async {
      final adapter = _FakeAdapter({'prod.example.com': status});
      await expectLater(
        _build(adapter, fallback: fallback).get<dynamic>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.length, 1);
    });
  }

  test('POST 는 404 여도 재시도하지 않는다', () async {
    final adapter = _FakeAdapter({'prod.example.com': 404});
    await expectLater(
      _build(adapter, fallback: fallback).post<dynamic>('/a'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.length, 1);
  });

  test('대체 주소가 없으면 재시도하지 않는다', () async {
    final adapter = _FakeAdapter({'prod.example.com': 404});
    await expectLater(
      _build(adapter).get<dynamic>('/a'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.length, 1);
  });
}
