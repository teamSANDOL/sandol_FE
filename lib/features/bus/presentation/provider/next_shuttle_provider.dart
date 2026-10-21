import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/fallback_interceptor.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/core/utils/korea_time.dart';

import 'package:handori/features/bus/data/data_source/remote_shuttle_schedule.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';
import 'package:handori/features/bus/domain/usecase/shuttle_transfer.dart';

part 'next_shuttle_provider.g.dart';

/// 셔틀 계산의 기준 시각(KST).
///
/// 홈·버스 상세 화면이 공유한다. 분이 바뀔 때마다 자동으로 갱신되므로
/// "N분 후 출발"이 화면을 켜둔 채로도 흘러간다. 당겨서 새로고침이나
/// 백그라운드 복귀처럼 즉시 맞춰야 할 때는 [refresh]를 부른다.
@Riverpod(keepAlive: true)
class ShuttleClock extends _$ShuttleClock {
  Timer? _timer;
  int _listeners = 0;
  bool _appVisible = true;

  @override
  DateTime build() {
    // 타이머는 실제로 구독하는 위젯이 있을 때만 돈다. build() 에서 바로 켜면
    // 라이프사이클 훅이 .notifier 로만 건드린 경우 아무도 안 보는데도 영원히
    // 돈다. keepAlive 라 provider 자체는 살아 있다.
    ref.onAddListener(() {
      _listeners++;
      _armIfNeeded();
    });
    ref.onRemoveListener(() {
      _listeners--;
      if (_listeners <= 0) _stop();
    });
    ref.onDispose(_stop);
    return _truncateToMinute(KoreaTime.now());
  }

  /// 현재 시각으로 즉시 갱신 — 다음 셔틀 정보 새로고침 진입점.
  /// 같은 분이면 상태를 바꾸지 않아 불필요한 재계산이 없다.
  void refresh() => _advanceIfMinuteChanged();

  /// 앱이 화면에서 사라지면(paused) 타이머를 멈추고, 돌아오면 즉시 맞춘 뒤
  /// 재개한다. 홈 탭이 IndexedStack 에 살아 있어 구독은 끊기지 않으므로
  /// 백그라운드 정지는 여기서만 할 수 있다.
  void setAppVisible(bool visible) {
    _appVisible = visible;
    if (visible) {
      _advanceIfMinuteChanged();
      _armIfNeeded();
    } else {
      _stop();
    }
  }

  void _advanceIfMinuteChanged() {
    final now = _truncateToMinute(KoreaTime.now());
    if (now != state) state = now;
  }

  void _armIfNeeded() {
    if (!_appVisible || _listeners <= 0 || _timer != null) return;
    _scheduleNextMinute();
  }

  /// 다음 분 경계 직후에 한 번 깨어난다. 폴링보다 깨어나는 횟수가 적고
  /// 분이 바뀌는 순간과 표시가 어긋나지 않는다.
  void _scheduleNextMinute() {
    final now = KoreaTime.now();
    final untilNextMinute = Duration(
      seconds: 59 - now.second,
      milliseconds: 1000 - now.millisecond + 50,
    );
    _timer = Timer(untilNextMinute, () {
      _timer = null;
      _advanceIfMinuteChanged();
      _armIfNeeded();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  static DateTime _truncateToMinute(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour, t.minute);
}

/// 서버에서 받은 오늘(KST) 셔틀 시간표. null 이면 내장 시간표를 쓴다.
///
/// 대체 순서는 서버 → 기기 캐시 → 내장 시간표다. 앱을 켜면 먼저 마지막 성공
/// 응답(캐시)을 올리고, 이어서 서버에서 받아 바꾼다. 서버가 실패(503 포함)하거나
/// 형식이 계약과 다르면(운영이 아직 옛 형식) 대체 서버에 1회 묻고, 그래도 안
/// 되면 캐시(없으면 내장)를 그대로 둔다. 응답은 날짜별이라
/// [shuttleClockProvider]의 날짜가 바뀌면(자정) 다시 받는다.
///
/// 캐시 본문의 `version`으로 `If-None-Match`를 붙여 304면 캐시를 그대로 쓴다.
/// 다만 version 은 날짜와 무관해 304 는 그날의 `day_type`·구간을 알려 주지
/// 않으므로, 캐시 날짜가 오늘일 때만 붙인다. 다른 날 캐시면 조건 없이 받는다.
@Riverpod(keepAlive: true)
class ShuttleScheduleSource extends _$ShuttleScheduleSource {
  static const cacheKey = 'bus.shuttle_timetable';
  static const _storage = FlutterSecureStorage();

  /// 지금 받는 날짜. 자정을 넘긴 뒤 늦게 끝난 전날 요청이 상태를 덮지 않게 한다.
  String? _date;

  @override
  RemoteShuttleSchedule? build() {
    final today = ref.watch(shuttleClockProvider.select(DateFormatter.isoDate));
    _date = today;
    _load(today);
    return null;
  }

  Future<void> _load(String today) async {
    RemoteShuttleSchedule? cached;
    try {
      final raw = await _storage.read(key: cacheKey);
      cached = raw == null ? null : RemoteShuttleSchedule.tryParse(raw);
    } catch (_) {
      // 캐시를 못 읽으면 서버 응답이나 내장 시간표로 넘어간다.
    }
    if (_date != today) return;
    if (cached != null && _usableOn(cached, today)) state = cached;
    // ponytail: 오프라인이 학기 경계를 넘기면 지난 학기 캐시가 남는다. 요일
    // 구분만 맞춰 보고 valid_from/valid_to 는 다시 보지 않는다.
    try {
      final sameDay = cached?.date == today;
      final dio = ref.read(staticInfoDioProvider);
      final res = await dio.get<String>(
        '/static-info/bus/timetable',
        queryParameters: {'date': today},
        options: Options(
          responseType: ResponseType.plain,
          headers: {if (sameDay) 'If-None-Match': '"${cached!.version}"'},
          // 304 는 오류가 아니라 "캐시 그대로"다.
          validateStatus: (s) => s != null && (s == 304 || s ~/ 100 == 2),
        ),
      );
      // 304: 오늘 날짜 캐시가 이미 올라가 있다.
      if (_date != today || res.statusCode == 304) return;
      var body = res.data;
      var remote = body == null ? null : RemoteShuttleSchedule.tryParse(body);
      // 이미 인터셉터가 대체 서버로 보낸 응답이면(baseUrl 이 다름) 다시 묻지 않는다.
      if (remote == null && res.requestOptions.baseUrl == dio.options.baseUrl) {
        // 운영이 아직 옛 형식을 200 으로 주면 대체 서버에 1회 묻는다. version 은
        // 내용 해시라 어느 서버에서 받은 캐시든 그대로 비교할 수 있다.
        final retried = await dio.interceptors
            .whereType<FallbackInterceptor>()
            .firstOrNull
            ?.retry(res.requestOptions);
        if (_date != today) return;
        final data = retried?.data;
        body = data is String ? data : null;
        remote = body == null ? null : RemoteShuttleSchedule.tryParse(body);
      }
      if (remote == null || body == null) return;
      state = remote;
      await _storage.write(key: cacheKey, value: body);
    } catch (_) {
      // 오프라인·서버 오류: 캐시 또는 내장 시간표를 그대로 쓴다.
    }
  }

  /// 서버를 못 받을 때 [cached]를 [today]에 써도 되는지. 같은 날이면 그대로,
  /// 다른 날이면 앱 공휴일 목록으로 본 오늘 요일 구분이 같을 때만 쓴다.
  static bool _usableOn(RemoteShuttleSchedule cached, String today) =>
      cached.date == today ||
      cached.dayType == ShuttleScheduleData.dayTypeOf(DateTime.parse(today));
}

/// 서버 정류장 id → 정류장. 서버 것이 있으면 그것을, 없으면 내장 상수를 쓴다.
@riverpod
Map<String, ShuttleStop> shuttleStops(Ref ref) => {
  ...ShuttleScheduleData.stops,
  ...?ref.watch(shuttleScheduleSourceProvider)?.stops,
};

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 시간표가 있으면 서버가 정한 그날 구간을 그대로 쓰고, 없으면 내장
/// 시간표를 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 고른다.
@riverpod
ShuttleTimetable? shuttleTimetable(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  final remote = ref.watch(shuttleScheduleSourceProvider);
  if (remote != null) {
    return remote.timetableFor(route: route, direction: direction);
  }
  return ShuttleScheduleData.timetableFor(
    route: route,
    direction: direction,
    dayType: ShuttleScheduleData.dayTypeOf(ref.watch(shuttleClockProvider)),
  );
}

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 [shuttleTimetableProvider]에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
@riverpod
NextShuttle nextShuttle(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  return NextShuttleCalculator.calculate(
    ref.watch(shuttleTimetableProvider(route: route, direction: direction)),
    ref.watch(shuttleClockProvider),
  );
}

/// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
@riverpod
List<ShuttleEntry> upcomingShuttles(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  return NextShuttleCalculator.upcoming(
    ref.watch(shuttleTimetableProvider(route: route, direction: direction)),
    ref.watch(shuttleClockProvider),
  );
}

/// 정왕역 ↔ 제2캠퍼스 방향의 본교 환승 연결(최대 3개). 본교를 거치지 않는
/// 방향이면 null.
@riverpod
List<ShuttleConnection>? shuttleTransfers(
  Ref ref, {
  required ShuttleDirection direction,
}) {
  final legs = ShuttleTransfer.legsOf(direction);
  if (legs == null) return null;
  final (first, second, ride) = legs;
  ShuttleTimetable? leg(ShuttleDirection d) =>
      ref.watch(shuttleTimetableProvider(route: d.route, direction: d));
  return ShuttleTransfer.connections(
    leg(first),
    leg(second),
    ref.watch(shuttleClockProvider),
    rideMinutes: ride,
  );
}
