/// 홈 '주요일정' 카드 한 건. 시각은 무시하고 달력 날짜로만 비교한다.
class ScheduleEvent {
  const ScheduleEvent({
    required this.title,
    required this.start,
    required this.end,
    this.url,
  });

  final String title;
  final DateTime start;

  /// 마지막 날 (포함)
  final DateTime end;

  /// '자세히보기' 링크. 없으면 링크를 숨긴다.
  final String? url;

  /// 고정 해제를 기억할 때 쓰는 키
  String get id => '${_date(start).toIso8601String()}|$title';

  bool isOverOn(DateTime today) => _date(today).isAfter(_date(end));

  /// 시작 전이면 `D-N`, 진행 중이면 `D-Day`
  String dDayOn(DateTime today) {
    final days = _date(start).difference(_date(today)).inDays;
    return days > 0 ? 'D-$days' : 'D-Day';
  }

  /// `2026.09.29 ~ 2026.10.01`. 하루짜리면 날짜 하나만.
  String get periodLabel =>
      _date(start) == _date(end)
          ? _format(start)
          : '${_format(start)} ~ ${_format(end)}';

  static DateTime _date(DateTime t) => DateTime.utc(t.year, t.month, t.day);

  static String _format(DateTime t) =>
      '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')}';
}
