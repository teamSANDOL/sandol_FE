import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/core/utils/korea_time.dart';

import 'package:handori/features/bus/data/data_source/remote_shuttle_schedule.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';

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

/// 서버에서 받은 셔틀 시간표. null 이면 내장 시간표를 쓴다.
///
/// 대체 순서는 서버 → 기기 캐시 → 내장 시간표다. 앱을 켜면 먼저 마지막 성공
/// 응답(캐시)을 올리고, 이어서 서버에서 받아 바꾼다. 서버가 실패하거나 쓸 수
/// 있는 노선이 없으면 캐시(없으면 내장)를 그대로 둔다. 시간표는 학기 단위로
/// 바뀌므로 앱 실행마다 한 번만 받는다.
@Riverpod(keepAlive: true)
class ShuttleScheduleSource extends _$ShuttleScheduleSource {
  static const cacheKey = 'bus.shuttle_timetable';
  static const _storage = FlutterSecureStorage();

  @override
  RemoteShuttleSchedule? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final cached = await _storage.read(key: cacheKey);
      final fromCache =
          cached == null ? null : RemoteShuttleSchedule.tryParse(cached);
      if (fromCache != null) state = fromCache;
    } catch (_) {
      // 캐시를 못 읽으면 서버 응답이나 내장 시간표로 넘어간다.
    }
    // ponytail: 오프라인이 학기 경계를 넘기면 지난 학기 캐시가 남는다. 서버가
    // 기간 필터를 하므로 앱은 valid_from/valid_to 를 다시 보지 않는다.
    try {
      final res = await ref
          .read(staticInfoDioProvider)
          .get<String>(
            '/static-info/bus/timetable',
            options: Options(responseType: ResponseType.plain),
          );
      final body = res.data;
      final remote = body == null ? null : RemoteShuttleSchedule.tryParse(body);
      if (remote == null) return;
      state = remote;
      await _storage.write(key: cacheKey, value: body);
    } catch (_) {
      // 오프라인·서버 오류: 캐시 또는 내장 시간표를 그대로 쓴다.
    }
  }
}

/// (노선·방향)별 [shuttleClockProvider] 기준 오늘 시간표. 미운행이면 null.
///
/// 서버 데이터가 그 노선을 다루면 서버 것을, 아니면 내장 시간표를 쓴다.
/// 다만 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버 시간표가
/// 하나라도 빠뜨리면 그 방향은 내장 시간표를 쓴다. 2026-10 운영 응답은 등교
/// 「17:00~22:17 도착버스 탑승」을 `22:17 막차` 한 줄로만 줘서, 그대로 쓰면
/// 저녁 등교 카드가 「22:17 출발」로 잘못 보인다. 서버가 구간을 주기 시작하면
/// 이 조건은 저절로 풀린다.
/// 공휴일 판정은 앱 공휴일 목록([ShuttleScheduleData.dayTypeOf])으로 한다.
/// 서버 `day_type`은 trip이 어느 요일 구분에 속하는지만 알려 주고 오늘이
/// 공휴일인지는 알려 주지 않기 때문이다.
@riverpod
ShuttleTimetable? shuttleTimetable(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  final dayType = ShuttleScheduleData.dayTypeOf(
    ref.watch(shuttleClockProvider),
  );
  final builtIn = ShuttleScheduleData.timetableFor(
    route: route,
    direction: direction,
    dayType: dayType,
  );
  final remote = ref.watch(shuttleScheduleSourceProvider);
  if (remote == null || !remote.routes.contains(route)) return builtIn;
  final fromServer = remote.timetableFor(
    route: route,
    direction: direction,
    dayType: dayType,
  );
  // ponytail: 학교가 구간 운행을 실제로 없애면 내장 시간표를 갱신할 때까지
  // 지난 내장 시간표가 쓰인다. 내장 시간표는 학기마다 갱신 대상이다.
  return _segmentTypes(fromServer).containsAll(_segmentTypes(builtIn))
      ? fromServer
      : builtIn;
}

Set<ShuttleEntryType> _segmentTypes(ShuttleTimetable? t) => {
  for (final e in t?.entries ?? const <ShuttleEntry>[])
    if (e.isSegment) e.type,
};

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
