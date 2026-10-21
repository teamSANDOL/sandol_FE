import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/push/push_service.dart';
import 'package:handori/core/router/route_paths.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

class _RecordingRegistrar implements PushTokenRegistrar {
  final calls = <(String, bool)>[];

  @override
  Future<void> register(String token, {required bool loggedIn}) async {
    calls.add((token, loggedIn));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pushTargetFrom', () {
    test('공지 payload 는 공지 상세로 간다', () {
      final target = pushTargetFrom({
        'type': 'notice',
        'id': '42',
        'url': 'https://www.tukorea.ac.kr/tukorea/1096/subview.do',
        'title': '수강신청 안내',
        'author': '학사팀',
        'created_at': '2026-10-21',
      });
      expect(target?.path, RoutePaths.noticeDetail);
      final notice = target?.extra as Notice;
      expect(notice.id, 42);
      expect(notice.title, '수강신청 안내');
    });

    test('허용된 탭 route 로 간다', () {
      expect(pushTargetFrom({'route': RoutePaths.bus})?.path, RoutePaths.bus);
    });

    test('허용 목록 밖 경로·도메인·형식은 무시한다', () {
      for (final data in <Map<String, dynamic>>[
        {'route': RoutePaths.withdrawConfirm},
        {'route': 'https://evil.example/phish'},
        {'route': '/notice/../user'},
        {
          'type': 'notice',
          'id': '1',
          'url': 'https://evil.example/',
          'title': 't',
        },
        {
          'type': 'notice',
          'id': '1',
          'url': 'http://www.tukorea.ac.kr/',
          'title': 't',
        },
        {
          'type': 'notice',
          'id': '1',
          'url': 'https://tukorea.ac.kr.evil.example/',
          'title': 't',
        },
        {
          'type': 'notice',
          'id': 'x',
          'url': 'https://www.tukorea.ac.kr/',
          'title': 't',
        },
        {'type': 'notice', 'id': '1', 'url': 'https://www.tukorea.ac.kr/'},
        {},
      ]) {
        expect(pushTargetFrom(data), isNull, reason: '$data');
      }
    });
  });

  test('Firebase 설정이 없어도 init 은 던지지 않고 푸시만 꺼진다', () async {
    final service = PushService(
      registrar: const NoopPushTokenRegistrar(),
      isLoggedIn: () async => false,
    );
    await service.init();
    expect(service.enabled, isFalse);
    expect(await service.requestPermission(), isFalse);
    expect(await service.takeLaunchTarget(), isNull);
  });

  test('발급·갱신된 토큰이 로그인 상태와 함께 등록 지점으로 간다', () async {
    final registrar = _RecordingRegistrar();
    var loggedIn = false;
    final service = PushService(
      registrar: registrar,
      isLoggedIn: () async => loggedIn,
    );
    final refreshes = StreamController<String>();
    service.attachTokens(Future.value('first-token'), refreshes.stream);
    await pumpEventQueue();
    loggedIn = true;
    refreshes.add('second-token');
    await pumpEventQueue();
    await service.reRegister();
    expect(registrar.calls, [
      ('first-token', false),
      ('second-token', true),
      ('second-token', true),
    ]);
    await refreshes.close();
  });
}
