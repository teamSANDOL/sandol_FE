import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:handori/features/auth/data/token_storage.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/domain/repository/auth_repository.dart';

/// 리프레시가 일시적으로 실패했다(네트워크·타임아웃·서버 5xx 등).
/// 세션은 그대로 유지되며 나중에 다시 시도하면 된다.
class AuthRefreshUnavailableException implements Exception {
  final Object cause;
  const AuthRefreshUnavailableException(this.cause);

  @override
  String toString() => 'AuthRefreshUnavailableException($cause)';
}

/// Keycloak OIDC(Authorization Code + PKCE) 기반 인증.
///
/// 브라우저로 `{issuer}/protocol/openid-connect/auth` 에 보내고,
/// 딥링크(redirectUri 커스텀 스킴)로 돌아온 code 를 flutter_appauth 가
/// 토큰으로 교환한다. discovery 문서 대신 엔드포인트를 직접 구성해
/// 로컬(Keycloak frontend URL 불일치) 환경에서도 동작한다.
///
/// 리프레시 정책:
/// - 동시에 여러 요청이 만료된 토큰을 만나도 리프레시는 한 번만 나간다
///   (single-flight). Dio 인스턴스가 여러 개라 인터셉터 단위 직렬화로는 부족.
/// - 서버가 `invalid_grant` 로 거절할 때만 세션을 지운다. 네트워크 오류 등은
///   [AuthRefreshUnavailableException] 으로 구분하고 세션을 유지한다.
/// - 리프레시 토큰 만료 시각(JWT `exp`)을 저장해 두고, 이미 지났으면
///   서버에 묻지 않고 바로 로그아웃 상태로 전환한다.
class AuthRepositoryImpl implements AuthRepository {
  final FlutterAppAuth _appAuth;
  final TokenStorage _storage;
  final String _issuer;
  final String _clientId;
  final String _redirectUri;

  /// `offline_access` 를 요청해 리프레시 토큰이 SSO 세션 유휴 시간(30분)이
  /// 아니라 오프라인 세션 유휴 시간(30일)을 따르게 한다. Keycloak 클라이언트에
  /// offline_access 스코프가 붙어 있어야 한다(기본 realm 설정은 Default).
  static const _scopes = ['openid', 'profile', 'email', 'offline_access'];

  /// 일시적 실패 후 이 시간 동안은 재시도하지 않는다. 요청마다 리프레시가
  /// 나가 서버를 두드리는 일을 막는다.
  static const _retryBackoff = Duration(seconds: 15);

  /// 기기 시계와 서버 시계의 차이를 이만큼 허용한다. 로컬 만료 판정은 이 값
  /// 이상 지난 경우에만 서버에 묻지 않고 세션을 지운다.
  static const _clockSkewTolerance = Duration(hours: 1);

  final _sessionController = StreamController<AuthSession?>.broadcast();
  Future<AuthSession?>? _inflightRefresh;
  DateTime? _retryNotBefore;

  /// 세션 세대. 로그인·로그아웃·탈퇴마다 올라간다. 리프레시는 시작할 때의
  /// 세대를 기억했다가 응답이 왔을 때 세대가 바뀌어 있으면 결과를 버린다.
  /// 그러지 않으면 로그아웃 직후 늦게 도착한 리프레시 응답이 지운 토큰을
  /// 다시 저장하고 화면을 로그인 상태로 되돌린다.
  int _generation = 0;

  /// Keycloak 직접 호출(폐기·로그아웃·계정 삭제)용. API 게이트웨이 Dio 와 달리
  /// baseUrl·인증 인터셉터가 없다. 테스트에서 어댑터를 바꿔 끼울 수 있다.
  final Dio _keycloakDio;

  AuthRepositoryImpl({
    required TokenStorage storage,
    required String issuer,
    required String clientId,
    required String redirectUri,
    FlutterAppAuth appAuth = const FlutterAppAuth(),
    Dio? keycloakDio,
  })  : _storage = storage,
        _issuer = issuer,
        _clientId = clientId,
        _redirectUri = redirectUri,
        _appAuth = appAuth,
        _keycloakDio = keycloakDio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              contentType: Headers.formUrlEncodedContentType,
            ));

  AuthorizationServiceConfiguration get _serviceConfiguration =>
      AuthorizationServiceConfiguration(
        authorizationEndpoint: '$_issuer/protocol/openid-connect/auth',
        tokenEndpoint: '$_issuer/protocol/openid-connect/token',
        endSessionEndpoint: '$_issuer/protocol/openid-connect/logout',
      );

  @override
  Stream<AuthSession?> get sessionChanges => _sessionController.stream;

  @override
  Future<AuthSession> login({bool useKakao = false}) async {
    _generation++;
    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        serviceConfiguration: _serviceConfiguration,
        scopes: _scopes,
        // Keycloak 전용: 카카오 IdP 로 직행해 Keycloak 로그인 화면을 건너뛴다.
        // alias 는 대소문자 구분 — 프로덕션 realm 에 'Kakao' 로 등록되어 있다.
        additionalParameters:
            useKakao ? const {'kc_idp_hint': 'Kakao'} : null,
      ),
    );
    final session = _toSession(response);
    _retryNotBefore = null;
    await _storage.save(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final saved = await _storage.read();
    if (saved == null) return null;
    if (saved.isAccessTokenValid()) return saved;
    try {
      return await _refresh();
    } on AuthRefreshUnavailableException catch (e) {
      // 일시적 문제: 로그인 상태는 유지한다. 다음 요청에서 다시 시도한다.
      debugPrint('토큰 리프레시 보류(세션 유지): ${e.cause}');
      return saved;
    }
  }

  @override
  Future<String?> getValidAccessToken() async {
    final saved = await _storage.read();
    if (saved == null) return null;
    if (saved.isAccessTokenValid()) return saved.accessToken;
    try {
      return (await _refresh())?.accessToken;
    } on AuthRefreshUnavailableException {
      // 만료된 토큰을 붙여 보내면 보호된 API 는 어차피 401 이고, 공개 API 는
      // 헤더가 없어도 된다. 세션은 유지하고 이번 요청만 비로그인으로 보낸다.
      return null;
    }
  }

  @override
  Future<void> logout() async {
    // 서버 호출 전에 세대를 올려, 진행 중이던 리프레시가 그 사이 끝나도
    // 결과를 버리게 한다.
    _generation++;
    final saved = await _storage.read();
    // 서버 세션 종료는 베스트 에포트: 실패해도 로컬 로그아웃은 진행한다.
    final refreshToken = saved?.refreshToken;
    if (refreshToken != null) {
      // 세션 종료(/logout)가 리프레시 토큰이 속한 사용자·오프라인 세션과 그 아래
      // 클라이언트 세션을 모두 끝낸다. 먼저 폐기(/revoke)하면 같은 토큰으로
      // 부르는 /logout 이 항상 invalid_grant 로 실패하므로, 순서는 종료 → 실패
      // 시에만 폐기로 대체한다.
      try {
        await _keycloakDio.post(
          '$_issuer/protocol/openid-connect/logout',
          data: {'client_id': _clientId, 'refresh_token': refreshToken},
        );
      } catch (e) {
        debugPrint('Keycloak 서버 로그아웃 실패, 토큰 폐기로 대체: $e');
        await _revokeRefreshToken(refreshToken, reason: '로그아웃 대체');
      }
    }
    await _storage.clear();
    // 서버 호출 중에 시작된 리프레시는 위에서 올린 세대를 이미 봤다. 비운 뒤
    // 한 번 더 올려 그 리프레시의 결과도 버려지게 한다.
    _generation++;
    _retryNotBefore = null;
  }

  /// 리프레시 토큰 폐기(베스트 에포트).
  Future<void> _revokeRefreshToken(String refreshToken,
      {required String reason}) async {
    try {
      await _keycloakDio.post(
        '$_issuer/protocol/openid-connect/revoke',
        data: {
          'client_id': _clientId,
          'token': refreshToken,
          'token_type_hint': 'refresh_token',
        },
      );
    } catch (e) {
      debugPrint('Keycloak 토큰 폐기 실패($reason): $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    // 사용자가 명시적으로 누른 동작이므로 일시 실패 백오프는 무시하고 지금
    // 유효한 토큰을 확보한다. 만료된 토큰으로 보내면 401 로 "탈퇴 실패"가 뜬다.
    _retryNotBefore = null;
    final session = await restoreSession();
    _generation++;
    if (session == null) {
      // 이미 세션이 없으면 지울 계정 접근 권한도 없다 — 로컬만 정리.
      await _storage.clear();
      _generation++;
      return;
    }
    if (!session.isAccessTokenValid()) {
      throw StateError('로그인 세션을 갱신하지 못해 탈퇴를 진행할 수 없습니다. '
          '네트워크를 확인한 뒤 다시 시도해 주세요.');
    }
    // Keycloak Account REST API. realm 에 'Delete Account' required action 이
    // 활성화되어 있고 사용자에게 account 클라이언트의 delete-account 롤이
    // 있어야 한다. 실패 시 예외를 그대로 올려 UI 에서 안내한다.
    await _keycloakDio.delete(
      '$_issuer/account',
      options: Options(
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      ),
    );
    await _storage.clear();
    _generation++;
  }

  // ── 리프레시 ───────────────────────────────────────────────────────────

  /// 진행 중인 리프레시가 있으면 그 결과를 공유한다(single-flight).
  Future<AuthSession?> _refresh() {
    final inflight = _inflightRefresh;
    if (inflight != null) return inflight;
    final future = _doRefresh().whenComplete(() => _inflightRefresh = null);
    _inflightRefresh = future;
    return future;
  }

  Future<AuthSession?> _doRefresh() async {
    // 다른 호출자가 먼저 갱신을 마쳤을 수 있으니 저장소를 다시 읽는다.
    final saved = await _storage.read();
    if (saved == null) return null;
    if (saved.isAccessTokenValid()) return saved;

    final refreshToken = saved.refreshToken;
    if (refreshToken == null ||
        !saved.isRefreshTokenValid(leeway: -_clockSkewTolerance)) {
      // 리프레시 토큰이 없거나 넉넉히 보아도 만료됨 — 서버에 묻지 않고 정리.
      // 만료 시각은 서버 시계(JWT exp) 기준이라 기기 시계가 앞서 있으면 멀쩡한
      // 토큰을 버릴 수 있다. 오차 허용치 안이면 서버에 물어 본다.
      debugPrint('리프레시 토큰 만료, 세션 제거');
      await _clearSession();
      return null;
    }

    final notBefore = _retryNotBefore;
    if (notBefore != null && DateTime.now().isBefore(notBefore)) {
      throw AuthRefreshUnavailableException(
        StateError('backoff until $notBefore'),
      );
    }

    final generation = _generation;
    try {
      final response = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfiguration,
          refreshToken: refreshToken,
          scopes: _scopes,
        ),
      );
      if (generation != _generation) {
        // 기다리는 동안 로그아웃·탈퇴·재로그인이 일어났다. 이 응답은 지난
        // 세대의 것이므로 저장하지도 흘리지도 않는다. 서버가 새로 발급한
        // 리프레시 토큰은 폐기해 둔다(로그아웃한 사용자의 세션이 남지 않게).
        // 호출자에게는 "지금의 진실"(로그아웃이면 null, 재로그인이면 새 세션)을
        // 돌려줘 늦게 온 결과가 화면 상태를 잘못 덮지 않게 한다.
        debugPrint('세대가 바뀐 리프레시 응답 폐기');
        final rotated = response.refreshToken;
        if (rotated != null) {
          await _revokeRefreshToken(rotated, reason: '늦게 도착한 리프레시');
        }
        return _storage.read();
      }
      // Keycloak 은 리프레시 토큰을 회전시킬 수 있다. 새 값이 없으면 기존 유지.
      final newRefreshToken = response.refreshToken ?? refreshToken;
      final session = AuthSession(
        accessToken: response.accessToken!,
        refreshToken: newRefreshToken,
        idToken: response.idToken ?? saved.idToken,
        accessTokenExpiresAt: response.accessTokenExpirationDateTime,
        refreshTokenExpiresAt: response.refreshToken == null
            ? saved.refreshTokenExpiresAt
            : _expiryFromJwt(newRefreshToken),
        username: saved.username ?? _usernameFromJwt(response.idToken),
        email: saved.email ?? _emailFromJwt(response.idToken),
      );
      _retryNotBefore = null;
      await _storage.save(session);
      _sessionController.add(session);
      return session;
    } catch (e) {
      if (generation != _generation) {
        // 지난 세대의 실패. 현재 상태를 건드리지 않고 지금의 진실을 돌려준다.
        return _storage.read();
      }
      if (_isRefreshTokenRejected(e)) {
        // 서버가 리프레시 토큰을 거절(만료/폐기/세션 없음) → 로그아웃 상태.
        debugPrint('리프레시 토큰 거절됨, 세션 제거: $e');
        await _clearSession();
        return null;
      }
      // 네트워크·서버 장애·설정 오류 등: 세션은 살려 두고 잠시 후 재시도.
      _retryNotBefore = DateTime.now().add(_retryBackoff);
      throw AuthRefreshUnavailableException(e);
    }
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    _retryNotBefore = null;
    _sessionController.add(null);
  }

  /// 리프레시 토큰으로는 더 이상 세션을 이어갈 수 없다고 서버가 확정한 경우.
  ///
  /// Keycloak 은 만료·폐기·재사용된 리프레시 토큰과 세션이 사라진 경우를
  /// `invalid_grant` 로 답한다. 스코프·클라이언트·권한 문제(`invalid_scope`,
  /// `unauthorized_client`, `invalid_client`, `not_allowed`, `access_denied`)도
  /// 다시 시도해서 풀리지 않으므로 같은 취급을 한다. 여기서 지우지 않으면
  /// 화면은 로그인 상태인데 모든 요청이 익명으로 나가고 15초마다 토큰
  /// 엔드포인트를 두드리는 "좀비 세션"이 된다. 네트워크·5xx 는 일시적이므로
  /// 세션을 유지한다.
  static const _permanentOAuthErrors = {
    'invalid_grant',
    'invalid_scope',
    'unauthorized_client',
    'invalid_client',
    'not_allowed',
    'access_denied',
  };

  static bool _isRefreshTokenRejected(Object e) {
    if (e is FlutterAppAuthPlatformException) {
      final details = e.platformErrorDetails;
      if (_permanentOAuthErrors.contains(details.error)) return true;
      // 일부 플랫폼 경로는 error 필드 없이 메시지에만 코드가 실린다.
      return _mentionsPermanentError(e.message) ||
          _mentionsPermanentError(details.errorDebugDescription);
    }
    if (e is PlatformException) return _mentionsPermanentError(e.message);
    return false;
  }

  static bool _mentionsPermanentError(String? text) =>
      text != null && _permanentOAuthErrors.any(text.contains);

  // ── 토큰 파싱 ──────────────────────────────────────────────────────────

  AuthSession _toSession(AuthorizationTokenResponse response) => AuthSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        idToken: response.idToken,
        accessTokenExpiresAt: response.accessTokenExpirationDateTime,
        refreshTokenExpiresAt: _expiryFromJwt(response.refreshToken),
        username: _usernameFromJwt(response.idToken) ??
            _usernameFromJwt(response.accessToken),
        email: _emailFromJwt(response.idToken) ??
            _emailFromJwt(response.accessToken),
      );

  /// JWT payload 에서 표시용 사용자명을 추출한다. (서명 검증은 하지 않는다 —
  /// 검증 책임은 토큰을 소비하는 리소스 서버에 있다.)
  static String? _usernameFromJwt(String? jwt) {
    final payload = _payloadFromJwt(jwt);
    if (payload == null) return null;
    return (payload['preferred_username'] ??
        payload['name'] ??
        payload['email']) as String?;
  }

  static String? _emailFromJwt(String? jwt) =>
      _payloadFromJwt(jwt)?['email'] as String?;

  /// JWT `exp` 클레임. Keycloak 오프라인 토큰은 `exp` 가 없거나 0 이라
  /// 그 경우 null(만료 없음)로 본다.
  @visibleForTesting
  static DateTime? expiryFromJwt(String? jwt) => _expiryFromJwt(jwt);

  static DateTime? _expiryFromJwt(String? jwt) {
    final exp = _payloadFromJwt(jwt)?['exp'];
    if (exp is! num || exp <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  }

  static Map<String, dynamic>? _payloadFromJwt(String? jwt) {
    if (jwt == null) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      return json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
