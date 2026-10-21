import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:handori/core/router/app_router.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

// 서버 푸시 수신 기반. 형식·서버 쪽 할 일은 docs/PUSH.md 참고.
// Firebase 설정 파일(google-services.json / GoogleService-Info.plist)이 없으면
// 초기화가 실패하고 푸시만 꺼진 채 앱은 그대로 동작한다.

/// 기기 푸시 토큰을 서버에 등록하는 지점. 토큰 등록 API 가 생기면 구현을 바꾼다.
abstract interface class PushTokenRegistrar {
  Future<void> register(String token, {required bool loggedIn});
}

/// 백엔드 API 가 아직 없어 아무것도 보내지 않는다.
class NoopPushTokenRegistrar implements PushTokenRegistrar {
  const NoopPushTokenRegistrar();

  @override
  Future<void> register(String token, {required bool loggedIn}) async {}
}

/// 알림 탭으로 이동할 화면.
typedef PushTarget = ({String path, Object? extra});

/// 탭 루트 중 `route` 키로 열 수 있는 화면. 목록에 없는 경로는 무시한다.
const _routeAllowlist = {
  RoutePaths.home,
  RoutePaths.meal,
  RoutePaths.bus,
  RoutePaths.notice,
  RoutePaths.map,
};

/// 공지 상세는 WebView 로 url 을 그대로 열므로 학교 도메인 https 만 허용한다.
bool _isSchoolUrl(Uri uri) =>
    uri.scheme == 'https' &&
    (uri.host == 'tukorea.ac.kr' || uri.host.endsWith('.tukorea.ac.kr'));

/// 알림 data → 이동할 화면. 약속에 맞지 않으면 null (임의 딥링크 차단).
PushTarget? pushTargetFrom(Map<String, dynamic> data) {
  if (data['type'] == 'notice') {
    final id = int.tryParse('${data['id']}');
    final uri = Uri.tryParse('${data['url']}');
    final title = data['title'];
    if (id == null || uri == null || !_isSchoolUrl(uri) || title is! String) {
      return null;
    }
    return (
      path: RoutePaths.noticeDetail,
      extra: Notice(
        id: id,
        url: uri.toString(),
        title: title,
        author: '${data['author'] ?? ''}',
        createdAt: '${data['created_at'] ?? ''}',
      ),
    );
  }
  final route = data['route'];
  if (route is String && _routeAllowlist.contains(route)) {
    return (path: route, extra: null);
  }
  return null;
}

/// 토큰은 로그에 앞 몇 글자만 남긴다.
String _mask(String token) =>
    '${token.substring(0, token.length < 6 ? token.length : 6)}…';

/// 백그라운드·종료 상태 수신. `notification` 이 있는 메시지는 OS 가 알림을 띄우므로
/// 지금은 할 일이 없다. 별도 isolate 에서 돌기 때문에 최상위 함수여야 한다.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

const _channel = AndroidNotificationChannel(
  // AndroidManifest 의 default_notification_channel_id 와 같아야 한다.
  'sandol_default',
  '산돌이 알림',
  importance: Importance.high,
);

class PushService {
  PushService({required this.registrar, required this.isLoggedIn});

  final PushTokenRegistrar registrar;
  final Future<bool> Function() isLoggedIn;

  final _local = FlutterLocalNotificationsPlugin();
  Future<void>? _initFuture;
  bool _enabled = false;
  String? _token;

  /// 스플래시가 이동을 끝내기 전에 탭한 알림. 이후 탭은 바로 이동한다.
  PushTarget? _pending;
  bool _routerReady = false;

  bool get enabled => _enabled;

  /// 앱 시작 시 한 번 호출. 실패해도 던지지 않는다.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase 초기화 실패, 푸시 없이 시작합니다: $e');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      // 권한 요청은 하지 않는다. iOS 기본값(true)이 시작 시 권한 창을 띄우므로 끈다.
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
        ),
        onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _openPayload(launch?.notificationResponse?.payload);
      }

      final messaging = FirebaseMessaging.instance;
      attachTokens(messaging.getToken(), messaging.onTokenRefresh);
      _enabled = true;
    } catch (e) {
      debugPrint('푸시 설정 실패, 푸시 없이 계속합니다: $e');
    }
  }

  /// 발급·갱신된 토큰을 등록 지점으로 넘긴다.
  @visibleForTesting
  void attachTokens(Future<String?> initial, Stream<String> refreshes) {
    initial.then((t) {
      if (t != null) _register(t);
    }, onError: (Object e) => debugPrint('푸시 토큰 발급 실패: $e'));
    refreshes.listen(_register);
  }

  Future<void> _register(String token) async {
    _token = token;
    debugPrint('푸시 토큰 수신: ${_mask(token)}');
    try {
      await registrar.register(token, loggedIn: await isLoggedIn());
    } catch (e) {
      debugPrint('푸시 토큰 등록 실패: $e');
    }
  }

  /// 로그인·로그아웃 뒤 같은 토큰을 새 로그인 상태로 다시 등록한다.
  Future<void> reRegister() async {
    final token = _token;
    if (token != null) await _register(token);
  }

  /// 기능이 생기면 설정 화면 등에서 호출한다. 지금은 어디서도 부르지 않는다.
  Future<bool> requestPermission() async {
    if (!_enabled) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// 스플래시 선로딩이 끝난 뒤 호출. 종료 상태에서 알림으로 연 경우의 이동 대상.
  Future<PushTarget?> takeLaunchTarget() async {
    await _initFuture;
    _routerReady = true;
    final target = _pending;
    _pending = null;
    return target;
  }

  /// 포그라운드에서는 OS 가 알림을 띄우지 않으므로 직접 띄운다.
  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openPayload(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) _open(data);
    } on FormatException {
      return;
    }
  }

  void _open(Map<String, dynamic> data) {
    final target = pushTargetFrom(data);
    if (target == null) return;
    if (_routerReady) {
      appRouter.go(target.path, extra: target.extra);
    } else {
      _pending = target;
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    registrar: const NoopPushTokenRegistrar(),
    isLoggedIn:
        () => ref
            .read(authNotifierProvider.future)
            .then((s) => s != null, onError: (_) => false),
  );
  ref.listen(authNotifierProvider.select((s) => s.valueOrNull != null), (
    prev,
    next,
  ) {
    if (prev != null && prev != next) service.reRegister();
  });
  return service;
});
