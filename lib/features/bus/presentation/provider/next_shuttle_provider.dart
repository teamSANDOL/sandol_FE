import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/utils/korea_time.dart';

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

/// (노선·방향)별 [shuttleClockProvider] 기준 다음 셔틀 정보.
///
/// 기준 시각으로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
/// 갱신은 `ref.read(shuttleClockProvider.notifier).refresh()`로 한다.
@riverpod
NextShuttle nextShuttle(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  final now = ref.watch(shuttleClockProvider);
  return NextShuttleCalculator.calculate(
    _timetableAt(now, route, direction),
    now,
  );
}

/// (노선·방향)별 [shuttleClockProvider] 기준 이후 시간표 항목(최대 3개).
@riverpod
List<ShuttleEntry> upcomingShuttles(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  final now = ref.watch(shuttleClockProvider);
  return NextShuttleCalculator.upcoming(
    _timetableAt(now, route, direction),
    now,
  );
}

ShuttleTimetable? _timetableAt(
  DateTime now,
  ShuttleRoute route,
  ShuttleDirection direction,
) => ShuttleScheduleData.timetableFor(
  route: route,
  direction: direction,
  dayType: ShuttleScheduleData.dayTypeOf(now),
);
