import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

// flutter_appauth 의 플랫폼 인터페이스를 직접 교체해 네이티브 채널 없이 테스트한다.
// ignore: depend_on_referenced_packages
import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/auth/data/repository/auth_repository_impl.dart';
import 'package:handori/features/auth/data/token_storage.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';

/// flutter_appauth 의 플랫폼 채널을 대체하는 가짜. token() 호출 횟수와
/// 결과(성공/예외)를 테스트가 제어한다.
class _FakeAppAuthPlatform extends FlutterAppAuthPlatform {
  int tokenCalls = 0;
  Future<TokenResponse> Function(TokenRequest request)? onToken;

  @override
  Future<TokenResponse> token(TokenRequest request) {
    tokenCalls++;
    return onToken!(request);
  }
}

/// Keycloak 직접 호출(폐기·로그아웃)을 네트워크 없이 받아 주는 어댑터.
class _FakeHttpAdapter implements HttpClientAdapter {
  final List<String> paths = [];

  /// 이 접미사로 끝나는 경로는 500 으로 응답한다.
  final Set<String> failPaths = {};

  /// 이 접미사로 끝나는 경로는 Completer 가 완료될 때까지 응답을 보류한다.
  final Map<String, Completer<void>> holdPaths = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    for (final entry in holdPaths.entries) {
      if (options.path.endsWith(entry.key)) await entry.value.future;
    }
    final fail = failPaths.any((p) => options.path.endsWith(p));
    return ResponseBody.fromString(
      fail ? '{"error":"server_error"}' : '{}',
      fail ? 500 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _jwt(Map<String, dynamic> payload) {
  String enc(Object o) =>
      base64Url.encode(utf8.encode(json.encode(o))).replaceAll('=', '');
  return '${enc({'alg': 'none'})}.${enc(payload)}.sig';
}

int _epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

FlutterAppAuthPlatformException _oauthError(String error) =>
    FlutterAppAuthPlatformException(
      code: 'token_failed',
      message: 'Failed to refresh token: $error',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(error: error),
    );

FlutterAppAuthPlatformException _networkError() =>
    FlutterAppAuthPlatformException(
      code: 'token_failed',
      message: 'Network error',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
        type: '0',
        code: '3',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAppAuthPlatform platform;
  late _FakeHttpAdapter http;
  late TokenStorage storage;
  late AuthRepositoryImpl repo;

  final expiredAccess = DateTime.now().subtract(const Duration(minutes: 1));
  final futureRefreshExp = DateTime.now().add(const Duration(days: 1));

  AuthSession expiredSession({DateTime? refreshExp}) => AuthSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        accessTokenExpiresAt: expiredAccess,
        refreshTokenExpiresAt: refreshExp ?? futureRefreshExp,
        username: 'tester',
      );

  TokenResponse okResponse() => TokenResponse(
        'new-access',
        _jwt({'exp': _epoch(futureRefreshExp)}),
        DateTime.now().add(const Duration(minutes: 10)),
        null,
        'Bearer',
        null,
        null,
      );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    platform = _FakeAppAuthPlatform();
    FlutterAppAuthPlatform.instance = platform;
    storage = TokenStorage(const FlutterSecureStorage());
    http = _FakeHttpAdapter();
    repo = AuthRepositoryImpl(
      storage: storage,
      issuer: 'https://example.test/realms/x',
      clientId: 'app',
      redirectUri: 'app://cb',
      keycloakDio: Dio()..httpClientAdapter = http,
    );
  });

  test('로그아웃 중 늦게 도착한 리프레시 응답은 버리고 새 토큰을 폐기한다',
      () async {
    await storage.save(expiredSession());
    final tokenGate = Completer<TokenResponse>();
    platform.onToken = (_) => tokenGate.future;
    final emitted = <AuthSession?>[];
    final sub = repo.sessionChanges.listen(emitted.add);

    // 1) 리프레시 시작 — 서버 응답을 기다리는 중
    final refreshing = repo.restoreSession();
    await Future<void>.delayed(Duration.zero);
    expect(platform.tokenCalls, 1);

    // 2) 그 사이 로그아웃
    await repo.logout();
    expect(await storage.read(), isNull);

    // 3) 늦게 리프레시 응답 도착
    tokenGate.complete(okResponse());
    final result = await refreshing;
    await Future<void>.delayed(Duration.zero);

    expect(result, isNull, reason: '지난 세대의 응답은 세션으로 쓰지 않는다');
    expect(await storage.read(), isNull, reason: '지운 토큰을 다시 저장하지 않는다');
    expect(emitted, isEmpty, reason: '로그인 상태로 되돌리는 이벤트가 없다');
    // 로그아웃은 /logout 1회로 끝나고(성공 시 /revoke 없음),
    // 늦게 온 응답이 발급한 새 토큰만 /revoke 1회.
    expect(http.paths.where((p) => p.endsWith('/logout')).length, 1);
    expect(http.paths.where((p) => p.endsWith('/revoke')).length, 1);
    await sub.cancel();
  });

  test('서버 로그아웃이 실패하면 토큰 폐기로 대체하고 로컬은 비운다', () async {
    await storage.save(expiredSession());
    http.failPaths.add('/logout');

    await repo.logout();

    expect(await storage.read(), isNull);
    expect(http.paths.where((p) => p.endsWith('/logout')).length, 1);
    expect(http.paths.where((p) => p.endsWith('/revoke')).length, 1);
  });

  test('로그아웃 서버 호출 중에 시작된 리프레시도 결과를 버린다', () async {
    await storage.save(expiredSession());
    final logoutGate = Completer<void>();
    http.holdPaths['/logout'] = logoutGate;
    final tokenGate = Completer<TokenResponse>();
    platform.onToken = (_) => tokenGate.future;
    final emitted = <AuthSession?>[];
    final sub = repo.sessionChanges.listen(emitted.add);

    // 1) 로그아웃 시작 — 서버 /logout 응답을 기다리는 중
    final loggingOut = repo.logout();
    await Future<void>.delayed(Duration.zero);

    // 2) 그 사이 만료 토큰으로 API 요청이 나가 리프레시가 시작됨
    final refreshing = repo.getValidAccessToken();
    await Future<void>.delayed(Duration.zero);
    expect(platform.tokenCalls, 1);

    // 3) 로그아웃이 끝나고(저장소 비움) 나서 리프레시 응답 도착
    logoutGate.complete();
    await loggingOut;
    tokenGate.complete(okResponse());
    final token = await refreshing;
    await Future<void>.delayed(Duration.zero);

    expect(token, isNull);
    expect(await storage.read(), isNull, reason: '지운 토큰을 다시 저장하지 않는다');
    expect(emitted, isEmpty);
    await sub.cancel();
  });

  test('로그아웃 중 리프레시가 실패로 끝나도 현재 상태를 건드리지 않는다',
      () async {
    await storage.save(expiredSession());
    final tokenGate = Completer<TokenResponse>();
    platform.onToken = (_) => tokenGate.future;
    final emitted = <AuthSession?>[];
    final sub = repo.sessionChanges.listen(emitted.add);

    final refreshing = repo.restoreSession();
    await Future<void>.delayed(Duration.zero);
    await repo.logout();
    tokenGate.completeError(_oauthError('invalid_grant'));
    final result = await refreshing;
    await Future<void>.delayed(Duration.zero);

    expect(result, isNull);
    // 세대가 달라 _clearSession 을 다시 타지 않으므로 null 을 또 흘리지 않는다.
    expect(emitted, isEmpty);
    await sub.cancel();
  });

  group('expiryFromJwt', () {
    test('exp 클레임을 시각으로 변환한다', () {
      final exp = DateTime(2030, 1, 1, 12);
      expect(
        AuthRepositoryImpl.expiryFromJwt(_jwt({'exp': _epoch(exp)})),
        exp,
      );
    });

    test('오프라인 토큰처럼 exp 가 0 이거나 없으면 null', () {
      expect(AuthRepositoryImpl.expiryFromJwt(_jwt({'exp': 0})), isNull);
      expect(AuthRepositoryImpl.expiryFromJwt(_jwt({'sub': 'u'})), isNull);
      expect(AuthRepositoryImpl.expiryFromJwt('not-a-jwt'), isNull);
    });
  });

  test('액세스 토큰이 유효하면 서버에 묻지 않는다', () async {
    await storage.save(AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ));
    expect(await repo.getValidAccessToken(), 'a');
    expect(platform.tokenCalls, 0);
  });

  test('만료되면 리프레시해 저장하고 세션 변경을 흘린다', () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async => okResponse();
    final emitted = <AuthSession?>[];
    final sub = repo.sessionChanges.listen(emitted.add);

    expect(await repo.getValidAccessToken(), 'new-access');
    await Future<void>.delayed(Duration.zero);

    expect(platform.tokenCalls, 1);
    final saved = await storage.read();
    expect(saved?.accessToken, 'new-access');
    expect(saved?.username, 'tester');
    expect(saved?.refreshTokenExpiresAt, isNotNull);
    expect(emitted.single?.accessToken, 'new-access');
    await sub.cancel();
  });

  test('invalid_grant 면 세션을 지우고 null 을 흘린다', () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async => throw _oauthError('invalid_grant');
    final emitted = <AuthSession?>[];
    final sub = repo.sessionChanges.listen(emitted.add);

    expect(await repo.restoreSession(), isNull);
    await Future<void>.delayed(Duration.zero);

    expect(await storage.read(), isNull);
    expect(emitted, [null]);
    await sub.cancel();
  });

  test('네트워크 오류면 세션을 유지하고 잠시 재시도하지 않는다', () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async => throw _networkError();

    // restoreSession: 로그인 상태 유지(저장된 세션 그대로).
    final restored = await repo.restoreSession();
    expect(restored?.accessToken, 'old-access');
    expect(await storage.read(), isNotNull);
    expect(platform.tokenCalls, 1);

    // getValidAccessToken: 이번 요청은 토큰 없이. 백오프 중이라 재호출 없음.
    expect(await repo.getValidAccessToken(), isNull);
    expect(platform.tokenCalls, 1);
  });

  test('서버 5xx 등 invalid_grant 가 아닌 OAuth 오류도 세션을 유지한다',
      () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async => throw _oauthError('server_error');
    expect(await repo.restoreSession(), isNotNull);
    expect(await storage.read(), isNotNull);
  });

  test('동시 요청이 몰려도 리프레시는 한 번만 나간다', () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return okResponse();
    };

    final results = await Future.wait([
      repo.getValidAccessToken(),
      repo.getValidAccessToken(),
      repo.restoreSession().then((s) => s?.accessToken),
    ]);

    expect(results, everyElement('new-access'));
    expect(platform.tokenCalls, 1);
  });

  test('리프레시 토큰 만료가 시계 오차 허용치(1시간)보다 지났으면 서버에 묻지 않고 바로 로그아웃',
      () async {
    await storage.save(expiredSession(
      refreshExp: DateTime.now().subtract(const Duration(hours: 2)),
    ));
    platform.onToken = (_) async => okResponse();

    expect(await repo.restoreSession(), isNull);
    expect(platform.tokenCalls, 0);
    expect(await storage.read(), isNull);
  });

  test('리프레시 토큰 만료가 오차 허용치 안이면 기기 시계를 믿지 않고 서버에 묻는다',
      () async {
    // 기기 시계가 앞서 있으면 멀쩡한 토큰의 exp 가 "조금 지난 것"으로 보인다.
    await storage.save(expiredSession(
      refreshExp: DateTime.now().subtract(const Duration(minutes: 1)),
    ));
    platform.onToken = (_) async => okResponse();

    expect((await repo.restoreSession())?.accessToken, 'new-access');
    expect(platform.tokenCalls, 1);
  });

  test('invalid_scope 같은 영구 OAuth 오류도 세션을 지운다(좀비 세션 방지)',
      () async {
    await storage.save(expiredSession());
    platform.onToken = (_) async => throw _oauthError('invalid_scope');

    expect(await repo.restoreSession(), isNull);
    expect(await storage.read(), isNull);
  });
}
