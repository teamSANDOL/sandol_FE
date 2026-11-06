/// 빈 강의실 조회 조건: 날짜(오늘부터 [daysAhead] 일 뒤) + 시각 구간
/// (0시 기준 분, 양끝 포함). 백엔드는 요일만 받으므로 날짜는 요일로 보낸다.
///
/// 오늘이면 축이 "지금"에서 시작하고, 다른 날이면 [dayStart] 에서 시작한다.
///
/// [anchorMinutes] 는 축의 시작("지금")으로, 조회 상태가 만들어질 때 한 번만
/// 읽어 둔다. 화면이 다시 그려질 때마다 시계를 읽지 않으므로 축이 흔들리지 않고,
/// 10분 이상 지났을 때만 [ClassroomQueryController.syncToNow] 로 다시 맞춘다.
class ClassroomQuery {
  /// DateTime.weekday 와 동일 (1=월 … 7=일)
  final int weekday;

  /// 오늘이면 0, 내일이면 1 … [maxDaysAhead] 까지
  final int daysAhead;

  /// 축의 시작 = 이 상태를 만들 당시의 현재 시각(분)
  final int anchorMinutes;
  final int startMinutes;
  final int endMinutes;

  const ClassroomQuery({
    required this.weekday,
    required this.anchorMinutes,
    required this.startMinutes,
    required this.endMinutes,
    this.daysAhead = 0,
  }) : assert(startMinutes < endMinutes);

  /// 기본 선택 폭 (지금부터 약 2시간, 정각에 맞춤)
  static const int defaultSpan = 120;

  /// 축의 마지막 정각. 14교시가 22:30 에 끝난다.
  static const int lastHourTick = 22 * 60;

  /// 축이 늦어도 여기서는 끝난다
  static const int hardEnd = 23 * 60 + 50;

  /// 다른 날의 축 시작 (1교시 09:30 직전 정각)
  static const int dayStart = 9 * 60;

  /// 고를 수 있는 날: 오늘부터 일주일
  static const int maxDaysAhead = 6;

  /// 앵커가 이만큼 오래되면 다시 맞춘다
  static const int staleAfter = 10;

  static const _dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

  static int minutesOf(DateTime t) =>
      (t.hour * 60 + t.minute).clamp(0, hardEnd - staleAfter);

  /// 축의 디텐트: `[지금, 다음 정각, …, 22:00]`. 밤늦게 정각이 없으면
  /// 한 시간 뒤(최대 23:50)를 하나 붙여 최소 한 칸은 만든다.
  static List<int> ticksFor(int anchor) {
    final ticks = <int>[anchor];
    for (var h = ((anchor ~/ 60) + 1) * 60; h <= lastHourTick; h += 60) {
      ticks.add(h);
    }
    if (ticks.length < 2) {
      ticks.add((anchor + 60).clamp(anchor + 1, hardEnd));
    }
    return ticks;
  }

  /// [minutes] 에 가장 가까운 디텐트의 인덱스
  static int nearestTickIndex(List<int> ticks, int minutes) {
    var best = 0;
    for (var i = 1; i < ticks.length; i++) {
      if ((ticks[i] - minutes).abs() < (ticks[best] - minutes).abs()) best = i;
    }
    return best;
  }

  /// 오늘 축에 고를 칸이 남아 있는가. 22시가 지나면 오늘은 고를 수 없다.
  static bool todaySelectable(DateTime now) => minutesOf(now) < lastHourTick;

  /// 기본 구간: 지금부터 2시간에 가장 가까운 정각까지. 21시가 넘어 오늘
  /// 남은 칸이 하나뿐이면 내일로 넘긴다.
  factory ClassroomQuery.defaultFor(DateTime now) =>
      ClassroomQuery.forDay(now, minutesOf(now) > lastHourTick - 60 ? 1 : 0);

  /// [now] 기준 [daysAhead] 일 뒤의 기본 구간.
  factory ClassroomQuery.forDay(DateTime now, int daysAhead) {
    if (daysAhead == 0) {
      final anchor = minutesOf(now);
      final ticks = ticksFor(anchor);
      var endIdx = nearestTickIndex(ticks, anchor + defaultSpan);
      if (endIdx == 0) endIdx = 1;
      return ClassroomQuery(
        weekday: now.weekday,
        anchorMinutes: anchor,
        startMinutes: anchor,
        endMinutes: ticks[endIdx],
      );
    }
    return ClassroomQuery(
      weekday: (now.weekday - 1 + daysAhead) % 7 + 1,
      daysAhead: daysAhead,
      anchorMinutes: dayStart,
      startMinutes: dayStart,
      endMinutes: dayStart + defaultSpan,
    );
  }

  bool get isToday => daysAhead == 0;

  List<int> get ticks => ticksFor(anchorMinutes);

  /// 백엔드 `day` 파라미터 형식 (예: `월요일`)
  String get dayName => _dayNames[weekday - 1];

  /// 짧은 요일 (예: `월`)
  String get dayShort => dayName.substring(0, 1);

  /// 백엔드 `start_time` / `end_time` 형식 (`HH:MM`)
  String get startTime => formatMinutes(startMinutes);
  String get endTime => formatMinutes(endMinutes);

  /// `13:52 ~ 16:00`
  String get timeLabel => '$startTime ~ $endTime';

  bool get isWeekend => weekday >= DateTime.saturday;

  /// 오늘 수업이 모두 끝난 뒤인가 (22:30 이후)
  bool get isAfterClassDay => isToday && anchorMinutes >= lastHourTick + 30;

  /// 분(minutes) → `HH:MM`
  static String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  ClassroomQuery copyWith({
    int? weekday,
    int? daysAhead,
    int? anchorMinutes,
    int? startMinutes,
    int? endMinutes,
  }) {
    return ClassroomQuery(
      weekday: weekday ?? this.weekday,
      daysAhead: daysAhead ?? this.daysAhead,
      anchorMinutes: anchorMinutes ?? this.anchorMinutes,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClassroomQuery &&
      other.weekday == weekday &&
      other.daysAhead == daysAhead &&
      other.anchorMinutes == anchorMinutes &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode =>
      Object.hash(weekday, daysAhead, anchorMinutes, startMinutes, endMinutes);

  @override
  String toString() => 'ClassroomQuery($dayName $timeLabel)';
}
