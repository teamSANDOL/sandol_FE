import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 마이페이지 알림 토글 3개의 값.
class NotificationSettings {
  const NotificationSettings({
    this.push = true,
    this.benefit = true,
    this.marketing = false,
  });

  final bool push;
  final bool benefit;
  final bool marketing;

  NotificationSettings copyWith({bool? push, bool? benefit, bool? marketing}) =>
      NotificationSettings(
        push: push ?? this.push,
        benefit: benefit ?? this.benefit,
        marketing: marketing ?? this.marketing,
      );
}

/// 알림 설정. 기기 로컬(flutter_secure_storage)에 저장한다.
///
/// 아직 서버로는 보내지 않는다(docs/PUSH.md). 서버 API 가 생기면 [_save] 에서
/// 함께 보낸다. 저장이 실패해도 메모리 상태는 유지되어 화면이 되돌아가지 않는다.
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _pushKey = 'notification.push';
  static const _benefitKey = 'notification.benefit';
  static const _marketingKey = 'notification.marketing';
  static const _storage = FlutterSecureStorage();

  @override
  NotificationSettings build() {
    _load();
    return const NotificationSettings();
  }

  Future<void> _load() async {
    try {
      final push = await _storage.read(key: _pushKey);
      final benefit = await _storage.read(key: _benefitKey);
      final marketing = await _storage.read(key: _marketingKey);
      // 저장된 값이 없는 항목은 지금 값(기본값 또는 읽는 동안 바꾼 값)을 둔다.
      state = NotificationSettings(
        push: push == null ? state.push : push == 'true',
        benefit: benefit == null ? state.benefit : benefit == 'true',
        marketing: marketing == null ? state.marketing : marketing == 'true',
      );
    } catch (_) {
      // 읽기 실패는 기본값으로 둔다.
    }
  }

  Future<void> _save(String key, bool value) async {
    try {
      await _storage.write(key: key, value: '$value');
    } catch (_) {
      // 저장 실패는 조용히 넘긴다. 다음 실행에서 기본값으로 돌아갈 뿐이다.
    }
  }

  Future<void> setPush(bool v) {
    state = state.copyWith(push: v);
    return _save(_pushKey, v);
  }

  Future<void> setBenefit(bool v) {
    state = state.copyWith(benefit: v);
    return _save(_benefitKey, v);
  }

  Future<void> setMarketing(bool v) {
    state = state.copyWith(marketing: v);
    return _save(_marketingKey, v);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
