import 'dart:convert';

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
    repo = AuthRepositoryImpl(
      storage: storage,
      issuer: 'https://example.test/realms/x',
      clientId: 'app',
      redirectUri: 'app://cb',
    );
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

  test('리프레시 토큰 만료가 지났으면 서버에 묻지 않고 바로 로그아웃', () async {
    await storage.save(expiredSession(
      refreshExp: DateTime.now().subtract(const Duration(minutes: 1)),
    ));
    platform.onToken = (_) async => okResponse();

    expect(await repo.restoreSession(), isNull);
    expect(platform.tokenCalls, 0);
    expect(await storage.read(), isNull);
  });
}
