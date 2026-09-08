import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 현재 시각 기준 다음 셔틀을 계산하는 순수 로직.
///
/// UI/Provider와 완전히 분리된 결정적 함수 — 동일 입력에 동일 출력.
class NextShuttleCalculator {
  const NextShuttleCalculator._();

  /// [timetable]이 null이면 미운행. [now] 기준으로 다음 셔틀 상태를 계산한다.
  static NextShuttle calculate(ShuttleTimetable? timetable, DateTime now) {
    if (timetable == null) {
      return const NextShuttle(
        status: ShuttleStatus.notOperating,
        statusLabel: '운행 안함',
        subText: '오늘은 운행하지 않아요',
      );
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final entries = timetable.entries;

    // 1) 현재 시각이 구간(수시운행·도착버스 탑승) 내부인지 우선 확인.
    for (final entry in entries) {
      if (entry.isSegment && entry.covers(nowMinutes)) {
        return _segment(entry);
      }
    }

    // 2) 시작 시각이 현재 이후인 가장 이른 항목을 탐색.
    //    아직 시작하지 않은 구간(예: 06:00에 본 08:40~10:00 수시운행)은
    //    "수시운행 중"이 아니라 그 시작 시각까지의 대기로 안내한다.
    for (final entry in entries) {
      if (entry.time.minutesOfDay < nowMinutes) continue;
      if (entry.isSegment && entry.time.minutesOfDay == nowMinutes) {
        return _segment(entry);
      }
      return NextShuttle(
        status: ShuttleStatus.upcoming,
        remainMinutes: entry.time.minutesOfDay - nowMinutes,
        departureTime: entry.time,
        subText: entry.isSegment
            ? '${entry.time.label}부터 ${_segmentName(entry)}'
            : '${entry.time.label} 출발',
      );
    }

    // 3) 남은 항목 없음 → 막차 종료.
    return const NextShuttle(
      status: ShuttleStatus.closed,
      statusLabel: '운행 종료',
      subText: '오늘 운행이 종료되었어요',
    );
  }

  static String _segmentName(ShuttleEntry entry) =>
      entry.type == ShuttleEntryType.flexible ? '수시운행' : '도착버스 탑승';

  /// 구간 항목(수시운행·도착버스 탑승) → 상태 변환.
  static NextShuttle _segment(ShuttleEntry entry) {
    final start = entry.time;
    final end = entry.endTime;
    if (entry.type == ShuttleEntryType.flexible) {
      return NextShuttle(
        status: ShuttleStatus.flexible,
        statusLabel: '수시운행',
        subText: end == null ? null : '${start.label}~${end.label} 수시운행',
      );
    }
    // arrivalBoarding
    final note = entry.boardingNote;
    final lastBus = end == null ? null : '막차 ${end.label}';
    return NextShuttle(
      status: ShuttleStatus.arrivalBoarding,
      statusLabel: '도착버스 탑승',
      subText: [note, lastBus].whereType<String>().join(' · '),
    );
  }
}
