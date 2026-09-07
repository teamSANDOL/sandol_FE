import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';

part 'next_shuttle_provider.g.dart';

/// 셔틀 계산의 기준 시각(= 마지막 새로고침 시각).
///
/// 홈·버스 상세 화면이 공유하며, [ShuttleClock.refresh]를 호출하면
/// 이 값을 watch하는 [nextShuttleProvider]가 모두 재계산된다.
@Riverpod(keepAlive: true)
class ShuttleClock extends _$ShuttleClock {
  @override
  DateTime build() => DateTime.now();

  /// 현재 시각으로 갱신 — 다음 셔틀 정보 새로고침 진입점.
  void refresh() => state = DateTime.now();
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
  final dayType = ShuttleScheduleData.dayTypeOf(now);
  final timetable = ShuttleScheduleData.timetableFor(
    route: route,
    direction: direction,
    dayType: dayType,
  );
  return NextShuttleCalculator.calculate(timetable, now);
}
