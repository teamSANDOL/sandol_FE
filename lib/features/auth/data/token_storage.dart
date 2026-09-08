import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';

/// 토큰을 기기 보안 저장소(Keychain/Keystore)에 보관한다.
/// 매 API 요청마다 저장소를 읽지 않도록 마지막 세션을 메모리에 캐시한다.
class TokenStorage {
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kIdToken = 'auth_id_token';
  static const _kExpiresAt = 'auth_access_expires_at';
  static const _kRefreshExpiresAt = 'auth_refresh_expires_at';
  static const _kUsername = 'auth_username';
  static const _kEmail = 'auth_email';

  final FlutterSecureStorage _storage;
  AuthSession? _cached;
  bool _loaded = false;

  TokenStorage(this._storage);

  /// 저장된 세션을 읽는다. 보통 한 번의 readAll 로 7개 키를 가져온다.
  ///
  /// 저장소 예외(잠긴 Keychain, Keystore 일시 오류, 복원 후 키 손상)는 위로
  /// 올리지 않는다. 올리면 스플래시가 멈춘다. 대신 이번 읽기만 비로그인으로
  /// 답하고 저장된 토큰은 지우지 않으며, 결과를 캐시하지 않아 다음 읽기(다음
  /// 요청·복귀)에서 다시 시도한다. 일시 오류면 그때 되살아나고, 진짜 손상이면
  /// 다시 로그인할 때 [save] 가 덮어써서 회복된다.
  ///
  /// readAll 은 같은 접두사의 모든 항목을 복호화하므로 다른 기능의 오래된
  /// 항목 하나가 깨져도 전체가 실패한다. 그 경우 필요한 키만 개별로 읽는다.
  Future<AuthSession?> read() async {
    if (_loaded) return _cached;
    Map<String, String?> values;
    try {
      values = await _storage.readAll();
    } catch (e) {
      debugPrint('보안 저장소 readAll 실패, 키별 읽기로 재시도: $e');
      try {
        values = {
          for (final key in _allKeys) key: await _storage.read(key: key),
        };
      } catch (e2) {
        debugPrint('보안 저장소 읽기 실패, 이번 읽기는 비로그인으로 진행: $e2');
        return null;
      }
    }
    final accessToken = values[_kAccessToken];
    _cached = accessToken == null
        ? null
        : AuthSession(
            accessToken: accessToken,
            refreshToken: values[_kRefreshToken],
            idToken: values[_kIdToken],
            accessTokenExpiresAt: _parseDateTime(values[_kExpiresAt]),
            refreshTokenExpiresAt: _parseDateTime(values[_kRefreshExpiresAt]),
            username: values[_kUsername],
            email: values[_kEmail],
          );
    _loaded = true;
    return _cached;
  }

  static const _allKeys = [
    _kAccessToken,
    _kRefreshToken,
    _kIdToken,
    _kExpiresAt,
    _kRefreshExpiresAt,
    _kUsername,
    _kEmail,
  ];

  Future<void> save(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: session.accessToken),
      _writeOrDelete(_kRefreshToken, session.refreshToken),
      _writeOrDelete(_kIdToken, session.idToken),
      // 시간대 표기 없이 저장하면 기기 시간대가 바뀐 뒤 읽을 때 벽시계로
      // 재해석돼 만료 판정이 최대 수 시간 어긋난다. 항상 UTC(Z) 로 저장한다.
      _writeOrDelete(
        _kExpiresAt,
        session.accessTokenExpiresAt?.toUtc().toIso8601String(),
      ),
      _writeOrDelete(
        _kRefreshExpiresAt,
        session.refreshTokenExpiresAt?.toUtc().toIso8601String(),
      ),
      _writeOrDelete(_kUsername, session.username),
      _writeOrDelete(_kEmail, session.email),
    ]);
    _cached = session;
    _loaded = true;
  }

  /// 로그아웃·탈퇴. 삭제 실패는 그대로 올려 호출자가 알게 한다(메모리만
  /// 비로그인이고 디스크에 토큰이 남는 불일치를 숨기지 않는다).
  Future<void> clear() async {
    await Future.wait([
      for (final key in _allKeys) _storage.delete(key: key),
    ]);
    _cached = null;
    _loaded = true;
  }

  static DateTime? _parseDateTime(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  Future<void> _writeOrDelete(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}
