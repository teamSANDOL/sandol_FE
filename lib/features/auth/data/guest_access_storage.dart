import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// "로그인 없이 둘러보기"를 고른 시각을 기기에 보관한다.
/// 이 기록이 [validFor] 안이면 앱 시작 때 로그인 화면 없이 바로 홈으로 간다.
class GuestAccessStorage {
  /// 둘러보기 기록이 유효한 기간.
  static const validFor = Duration(days: 7);

  static const _kStartedAt = 'guest_browsing_started_at';

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  GuestAccessStorage(this._storage, {DateTime Function() now = DateTime.now})
    : _now = now;

  /// 지금을 둘러보기 시작 시각으로 기록(갱신)한다. 쓰기 실패는 로그인 화면으로
  /// 한 번 더 돌아올 뿐이라 막지 않는다.
  Future<void> start() async {
    try {
      await _storage.write(
        key: _kStartedAt,
        // 시간대가 바뀌어도 같은 시점으로 읽히도록 UTC 로 저장한다.
        value: _now().toUtc().toIso8601String(),
      );
    } catch (e) {
      debugPrint('보안 저장소 쓰기 실패(둘러보기 기록): $e');
    }
  }

  /// 로그인 성공·로그아웃 때 지운다.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kStartedAt);
    } catch (e) {
      debugPrint('보안 저장소 삭제 실패(둘러보기 기록): $e');
    }
  }

  /// 기록이 있고 [validFor] 가 지나지 않았는지. 읽기 실패·손상된 값, 그리고
  /// 기기 시간이 과거로 돌아가 기록이 미래인 경우는 만료로 본다.
  Future<bool> isActive() async {
    try {
      final raw = await _storage.read(key: _kStartedAt);
      final startedAt = raw == null ? null : DateTime.tryParse(raw);
      if (startedAt == null) return false;
      final elapsed = _now().difference(startedAt);
      return !elapsed.isNegative && elapsed < validFor;
    } catch (e) {
      debugPrint('보안 저장소 읽기 실패(둘러보기 기록), 로그인 화면으로: $e');
      return false;
    }
  }
}
