import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 본교 환승 연결 하나. [first]는 1구간 항목(정시편이면 [departure]가 그 시각,
/// 수시운행·도착버스 구간이면 그 구간 안에서 타는 시각), [transfer]는 본교에서
/// 갈아탈 2구간 출발 시각.
typedef ShuttleConnection =
    ({ShuttleEntry first, ShuttleTime departure, ShuttleTime transfer});

/// 정왕역 ↔ 제2캠퍼스를 본교에서 갈아타 가는 연결을 계산하는 순수 로직.
class ShuttleTransfer {
  const ShuttleTransfer._();

  /// 정왕역 ↔ 본교 소요시간(분). 학교 시간표 PDF 각주 "소요시간 10분".
  static const int stationMinutes = 10;

  /// 본교 ↔ 제2캠퍼스 소요시간(분).
  // ponytail: 원문에 근거 없는 추정값이다. 서버 데이터에 소요시간이 생기면 그 값으로 바꾼다.
  static const int campus2Minutes = 15;

  /// [direction](정왕역 ↔ 제2캠퍼스)의 1구간·2구간 방향과 1구간 소요시간.
  /// 본교를 거치지 않는 방향이면 null.
  static (ShuttleDirection, ShuttleDirection, int)? legsOf(
    ShuttleDirection direction,
  ) => switch (direction) {
    ShuttleDirection.jeongwangToCampus2 => (
      ShuttleDirection.jeongwangToSchool,
      ShuttleDirection.schoolToCampus2,
      stationMinutes,
    ),
    ShuttleDirection.campus2ToJeongwang => (
      ShuttleDirection.campus2ToSchool,
      ShuttleDirection.schoolToJeongwang,
      campus2Minutes,
    ),
    _ => null,
  };

  /// [now] 이후 1구간 [first]를 타고 [rideMinutes] 뒤 본교에 내려 2구간
  /// [second]로 갈아타는 연결을 환승 시각순으로 최대 [count]개.
  ///
  /// 1구간 수시운행·도착버스 구간은 구간 안 아무 때나 탈 수 있다고 보고, 지금
  /// (또는 구간 시작) 탄다고 계산한다. 같은 2구간 편으로 이어지는 1구간이 여럿이면
  /// 가장 늦게 출발하는 것을 남긴다(본교에서 덜 기다린다).
  static List<ShuttleConnection> connections(
    ShuttleTimetable? first,
    ShuttleTimetable? second,
    DateTime now, {
    required int rideMinutes,
    int count = 3,
  }) {
    if (first == null || second == null) return const [];
    final nowMinutes = now.hour * 60 + now.minute;
    final byTransfer = <int, ShuttleConnection>{};
    for (final entry in first.entries) {
      final start = entry.time.minutesOfDay;
      final end = entry.endTime?.minutesOfDay;
      final int depart;
      if (entry.isSegment && end != null) {
        if (end <= nowMinutes) continue;
        depart = start > nowMinutes ? start : nowMinutes;
      } else {
        if (start < nowMinutes) continue;
        depart = start;
      }
      final transfer = _firstDeparture(second, depart + rideMinutes);
      if (transfer == null) continue;
      byTransfer[transfer] = (
        first: entry,
        departure: ShuttleTime(depart ~/ 60, depart % 60),
        transfer: ShuttleTime(transfer ~/ 60, transfer % 60),
      );
    }
    final keys = byTransfer.keys.toList()..sort();
    return [for (final k in keys.take(count)) byTransfer[k]!];
  }

  /// [minutes] 이후 [t]에서 탈 수 있는 가장 이른 시각(분). 수시운행·도착버스
  /// 구간 안이면 그 시각 바로. 없으면 null.
  static int? _firstDeparture(ShuttleTimetable t, int minutes) {
    int? best;
    for (final e in t.entries) {
      final int candidate;
      if (e.covers(minutes)) {
        candidate = minutes;
      } else if (e.time.minutesOfDay >= minutes) {
        candidate = e.time.minutesOfDay;
      } else {
        continue;
      }
      if (best == null || candidate < best) best = candidate;
    }
    return best;
  }
}
