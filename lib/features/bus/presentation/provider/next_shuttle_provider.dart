import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';

part 'next_shuttle_provider.g.dart';

/// (노선·방향)별 현재 시각 기준 다음 셔틀 정보.
///
/// `DateTime.now()`로 요일·시각을 판정해 하드코딩 시간표에서 다음 셔틀을 계산한다.
/// 화면 진입 시점 기준 1회 계산이며, 갱신이 필요하면 `ref.invalidate`로 재계산한다.
@riverpod
NextShuttle nextShuttle(
  Ref ref, {
  required ShuttleRoute route,
  required ShuttleDirection direction,
}) {
  final now = DateTime.now();
  final dayType = ShuttleScheduleData.dayTypeOf(now);
  final timetable = ShuttleScheduleData.timetableFor(
    route: route,
    direction: direction,
    dayType: dayType,
  );
  return NextShuttleCalculator.calculate(timetable, now);
}
