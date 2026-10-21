import 'dart:convert';

import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// static-info `GET /static-info/bus/timetable` 응답을 도메인 시간표로 바꾼 것.
///
/// 서버는 오늘(KST) 운행 기간에 해당하는 trip만 주고 중복도 걸러 준다. 앱은
/// trip 하나를 [ShuttleEntry] 하나로 옮기기만 하고, 계산·표시는 내장 시간표와
/// 같은 [ShuttleTimetable] 경로를 탄다.
///
/// 노선 단위로 채택한다: 한 노선의 두 방향이 모두 응답에 있어야 그 노선을
/// 서버 데이터로 쓰고([routes]), 한 방향만 있으면 파싱이 덜 된 것으로 보고
/// 그 노선은 내장 시간표를 쓴다.
class RemoteShuttleSchedule {
  final Map<
    (ShuttleRoute, ShuttleDirection, ShuttleDayType),
    List<ShuttleEntry>
  >
  _entries;

  /// 서버 데이터로 쓰는 노선. 여기 없는 노선은 내장 시간표를 쓴다.
  final Set<ShuttleRoute> routes;

  const RemoteShuttleSchedule._(this._entries, this.routes);

  /// 응답 본문(JSON 문자열)을 해석한다. 형식이 틀렸거나 쓸 수 있는 노선이
  /// 하나도 없으면(빈 응답 포함) null.
  static RemoteShuttleSchedule? tryParse(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map || json['trips'] is! List) return null;

    final grouped =
        <
          (ShuttleRoute, ShuttleDirection, ShuttleDayType),
          List<ShuttleEntry>
        >{};
    for (final trip in (json['trips'] as List).whereType<Map>()) {
      final direction = _directionOf(trip['origin'], trip['destination']);
      final entry = _entryOf(trip);
      if (direction == null || entry == null) continue;
      for (final day in _dayTypesOf(trip['day_type'])) {
        grouped
            .putIfAbsent((_routeOf(direction), direction, day), () => [])
            .add(entry);
      }
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.time.minutesOfDay.compareTo(b.time.minutesOfDay));
    }

    final present = {for (final key in grouped.keys) key.$2};
    final routes = {
      for (final route in ShuttleRoute.values)
        if (_directionsOf(route).every(present.contains)) route,
    };
    if (routes.isEmpty) return null;
    return RemoteShuttleSchedule._(grouped, routes);
  }

  /// [route]가 [routes]에 있을 때만 의미가 있다. 해당 요일 trip이 없으면
  /// 미운행(null).
  ShuttleTimetable? timetableFor({
    required ShuttleRoute route,
    required ShuttleDirection direction,
    required ShuttleDayType dayType,
  }) {
    final entries = _entries[(route, direction, dayType)];
    if (entries == null) return null;
    return ShuttleTimetable(
      route: route,
      direction: direction,
      dayType: dayType,
      entries: entries,
    );
  }

  /// 출발지·도착지 → 방향. 경유지(via)는 보지 않는다. 서버 정류장 이름은
  /// `정왕역`·`본교`·`제2캠퍼스` 셋이다(static-info `SHUTTLE_DIRECTIONS`).
  /// 화면 표기(`한국공학대 정문` 등)는 앱이 따로 정한다.
  static ShuttleDirection? _directionOf(Object? origin, Object? destination) =>
      switch ((origin, destination)) {
        ('정왕역', '본교') => ShuttleDirection.jeongwangToSchool,
        ('본교', '정왕역') => ShuttleDirection.schoolToJeongwang,
        // 토요일 '정왕역 → 본교 → 제2캠퍼스'도 제2캠퍼스행으로 묶는다.
        (_, '제2캠퍼스') => ShuttleDirection.schoolToCampus2,
        ('제2캠퍼스', _) => ShuttleDirection.campus2ToSchool,
        _ => null,
      };

  static ShuttleRoute _routeOf(ShuttleDirection d) => switch (d) {
    ShuttleDirection.jeongwangToSchool ||
    ShuttleDirection.schoolToJeongwang => ShuttleRoute.route1,
    ShuttleDirection.schoolToCampus2 ||
    ShuttleDirection.campus2ToSchool => ShuttleRoute.route2,
  };

  static List<ShuttleDirection> _directionsOf(ShuttleRoute r) =>
      ShuttleDirection.values.where((d) => _routeOf(d) == r).toList();

  /// 서버 `day_type` → 앱 요일 구분. 앱은 일요일과 공휴일을 [ShuttleDayType.holiday]
  /// 하나로 보므로 `일요일`·`공휴일` trip은 둘 다 그날에 쓰인다.
  // ponytail: 일요일·공휴일 운행표가 서로 달라지면 ShuttleDayType 을 나눠야 한다.
  static List<ShuttleDayType> _dayTypesOf(Object? dayType) => switch (dayType) {
    '평일' => const [ShuttleDayType.weekday],
    '토요일' => const [ShuttleDayType.saturday],
    '주말' => const [ShuttleDayType.saturday, ShuttleDayType.holiday],
    '일요일' || '공휴일' => const [ShuttleDayType.holiday],
    _ => const [],
  };

  /// trip → 시간표 항목. 종료 시각이 있으면 구간 항목이고, 비고에
  /// '도착버스'가 있으면 도착버스 탑승, 아니면 수시운행이다.
  static ShuttleEntry? _entryOf(Map<dynamic, dynamic> trip) {
    final start = _timeOf(trip['departure_time']);
    if (start == null) return null;
    final end = _timeOf(trip['departure_time_end']);
    if (end == null || end.minutesOfDay <= start.minutesOfDay) {
      return ShuttleEntry.fixed(start);
    }
    final note = trip['note'];
    if (note is String && note.contains('도착버스')) {
      final place = trip['boarding_place'];
      return ShuttleEntry.arrivalBoarding(
        start,
        end,
        boardingNote: place is String ? '$place에서 도착 버스 탑승' : '도착 버스 탑승',
      );
    }
    return ShuttleEntry.flexible(start, end);
  }

  /// "HH:MM" → [ShuttleTime]. 형식이 다르면 null.
  static ShuttleTime? _timeOf(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (m == null) return null;
    final hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return ShuttleTime(hour, minute);
  }
}
