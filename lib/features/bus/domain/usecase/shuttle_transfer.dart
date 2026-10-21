import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 본교 환승 연결 하나. [first]는 1구간 항목(정시편이면 [departure]가 그 시각,
/// 수시운행·도착버스 구간이면 그 구간 안에서 타는 시각), [transfer]는 본교에서
/// 갈아탈 2구간 출발 시각. [tight]면 간격이 [ShuttleTransfer.safeGapMinutes]보다
/// 짧은("빠듯함") 연결이다.
typedef ShuttleConnection =
    ({
      ShuttleEntry first,
      ShuttleTime departure,
      ShuttleTime transfer,
      bool tight,
    });

/// 정왕역 ↔ 제2캠퍼스를 본교에서 갈아타 가는 연결을 계산하는 순수 로직.
class ShuttleTransfer {
  const ShuttleTransfer._();

  /// 1구간 출발 → 2구간 출발 최소 간격(분). 이동과 환승을 합친 안전 여유로,
  /// 양방향 공통이다.
  // ponytail: 사용자가 정한 안전 여유값(정왕역↔본교 10분 + 여유, 본교↔제2캠퍼스는
  // 원문에 소요시간이 없음). 서버가 구간 소요시간을 주면 방향별로 바꾼다.
  static const int safeGapMinutes = 20;

  /// "빠듯함"으로라도 보여 줄 최소 간격(분). 이보다 짧으면 갈아탈 수 없다고 본다.
  // ponytail: 정왕역↔본교 소요시간(시간표 각주 10분)을 그대로 쓴 하한.
  static const int tightGapMinutes = 10;

  /// [direction](정왕역 ↔ 제2캠퍼스)의 1구간·2구간 방향. 본교를 거치지 않는
  /// 방향이면 null.
  static (ShuttleDirection, ShuttleDirection)? legsOf(
    ShuttleDirection direction,
  ) => switch (direction) {
    ShuttleDirection.jeongwangToCampus2 => (
      ShuttleDirection.jeongwangToSchool,
      ShuttleDirection.schoolToCampus2,
    ),
    ShuttleDirection.campus2ToJeongwang => (
      ShuttleDirection.campus2ToSchool,
      ShuttleDirection.schoolToJeongwang,
    ),
    _ => null,
  };

  /// [now] 이후 1구간 [first]로 출발해 [safeGapMinutes] 뒤 이후의 첫 2구간
  /// [second]로 갈아타는 연결을 환승 시각순으로 최대 [count]개.
  ///
  /// 1구간 수시운행·도착버스 구간은 구간 안 아무 때나 탈 수 있다고 보고, 지금
  /// (또는 구간 시작) 탄다고 계산한다. 같은 2구간 편으로 이어지는 1구간이 여럿이면
  /// 가장 늦게 출발하는 것을 남긴다(본교에서 덜 기다린다). 빠듯한 연결([tight])도
  /// 함께 출발 시각순으로 섞여 나오며, 기본 목록은 이를 걸러 쓴다.
  static List<ShuttleConnection> connections(
    ShuttleTimetable? first,
    ShuttleTimetable? second,
    DateTime now, {
    int count = 3,
  }) {
    if (first == null || second == null) return const [];
    final nowMinutes = now.hour * 60 + now.minute;
    final byTransfer = <int, (ShuttleEntry, int)>{};
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
      final transfer = _firstDeparture(second, depart + safeGapMinutes);
      if (transfer != null) byTransfer[transfer] = (entry, depart);
    }
    final keys = byTransfer.keys.toList()..sort();
    final safe = [
      for (final transfer in keys.take(count))
        if (byTransfer[transfer] case (final entry, final depart))
          (
            first: entry,
            departure: _time(depart),
            transfer: _time(transfer),
            tight: false,
          ),
    ];

    // 빠듯한 연결: 지금 이후 1구간 정시편 중 간격이 tightGap 이상 safeGap 미만인
    // 것. 안전 연결이 없는 환승편이어도 넣고, 안전 목록이 덮는 시각까지만 남긴다
    // (안전 연결이 없으면 앞에서 count 개).
    final lastSafe = safe.isEmpty ? null : safe.last.transfer.minutesOfDay;
    final tight = <ShuttleConnection>[
      for (final e in first.entries)
        if (!e.isSegment && e.time.minutesOfDay >= nowMinutes)
          if (_firstDeparture(second, e.time.minutesOfDay + tightGapMinutes)
              case final transfer?
              when transfer - e.time.minutesOfDay < safeGapMinutes &&
                  (lastSafe == null || transfer <= lastSafe))
            (
              first: e,
              departure: e.time,
              transfer: _time(transfer),
              tight: true,
            ),
    ];
    return [...safe, ...(lastSafe == null ? tight.take(count) : tight)]..sort(
      (a, b) =>
          a.departure.minutesOfDay != b.departure.minutesOfDay
              ? a.departure.minutesOfDay.compareTo(b.departure.minutesOfDay)
              : a.transfer.minutesOfDay.compareTo(b.transfer.minutesOfDay),
    );
  }

  static ShuttleTime _time(int minutes) =>
      ShuttleTime(minutes ~/ 60, minutes % 60);

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
