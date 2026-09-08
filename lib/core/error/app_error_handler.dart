import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 크래시 리포팅 백엔드 연결 지점.
///
/// Firebase Crashlytics 나 Sentry 를 붙일 때 이 타입을 구현해
/// [installGlobalErrorHandlers] 에 넘기면 된다. 기본값은 로그만 남긴다.
abstract class CrashReporter {
  Future<void> record(Object error, StackTrace? stack, {bool fatal});
}

class _LogOnlyCrashReporter implements CrashReporter {
  // 기본 DevelopmentFilter 는 릴리즈(assert 꺼짐)에서 모든 로그를 버린다.
  // 릴리즈에서 logcat 에 남기는 것이 이 핸들러의 존재 이유이므로 항상 출력한다.
  final _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(methodCount: 8, errorMethodCount: 12),
  );

  @override
  Future<void> record(Object error, StackTrace? stack, {bool fatal = false}) {
    _logger.e(
      fatal ? '처리되지 않은 예외' : 'Flutter 프레임워크 오류',
      error: error,
      stackTrace: stack,
    );
    return Future.value();
  }
}

/// 앱 전역 예외 훅을 설치한다. `runApp` 전에 한 번 호출한다.
///
/// - [FlutterError.onError]: 위젯 빌드·레이아웃·페인트 중 예외. 릴리즈에서는
///   기본 동작이 로그만 남기고 회색 화면을 그리므로 여기서 리포터로 보낸다.
/// - [PlatformDispatcher.onError]: 그 밖의 모든 비동기 예외(Future, Timer,
///   플랫폼 채널). 기본 동작은 조용히 삼키는 것이라 팀이 알 방법이 없었다.
///
void installGlobalErrorHandlers({CrashReporter? reporter}) {
  final crashReporter = reporter ?? _LogOnlyCrashReporter();

  // 원래 핸들러(기본값은 콘솔 덤프)는 그대로 두고 리포팅만 덧붙인다.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    defaultOnError?.call(details);
    crashReporter.record(details.exception, details.stack, fatal: false);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crashReporter.record(error, stack, fatal: true);
    // true = 처리됨. 반환하지 않으면 릴리즈에서 예외가 격리 영역 밖으로
    // 빠져나가 로그조차 남지 않는다.
    return true;
  };
}
