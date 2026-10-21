import 'dart:convert';

import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// static-info `GET /static-info/bus/timetable?date=` 응답(하루치)을 도메인
/// 시간표로 바꾼 것.
///
/// 서버가 그날의 요일 구분(`day_type`, 공휴일 포함)과 방향별 구간을 확정해
/// 주므로 앱은 구간 하나를 [ShuttleEntry] 하나로 옮기기만 한다. 계산·표시는
/// 내장 시간표와 같은 [ShuttleTimetable] 경로를 탄다.
class RemoteShuttleSchedule {
  /// 응답이 가리키는 날짜(`YYYY-MM-DD`, KST).
  final String date;
  final ShuttleDayType dayType;

  /// 시간표 내용 해시. 날짜와 무관하다(`If-None-Match`에 쓴다).
  final String version;

  /// 최신 파싱이 검증에 실패해 직전 정상본을 내보내는 중인지.
  final bool needsReview;

  /// 서버 정류장 id → 정류장.
  final Map<String, ShuttleStop> stops;

  final Map<ShuttleDirection, List<ShuttleEntry>> _entries;

  const RemoteShuttleSchedule._({
    required this.date,
    required this.dayType,
    required this.version,
    required this.needsReview,
    required this.stops,
    required Map<ShuttleDirection, List<ShuttleEntry>> entries,
  }) : _entries = entries;

  /// 응답 본문(JSON 문자열)을 해석한다. 계약과 형식이 다르면(방향 6개 중
  /// 하나라도 없거나, 모르는 구간 종류·시각 형식 포함) null. 일부만 쓰면
  /// 구간을 빠뜨린 시간표가 정시편처럼 보일 수 있어 통째로 버린다.
  static RemoteShuttleSchedule? tryParse(String body) {
    try {
      return _parse(jsonDecode(body));
    } on FormatException {
      return null;
    } on TypeError {
      // 필드 타입이 계약과 다름(예: segments 가 리스트가 아님).
      return null;
    }
  }

  static RemoteShuttleSchedule? _parse(Object? json) {
    if (json is! Map) return null;
    final date = json['date'];
    final version = json['version'];
    final dayType = _dayTypeOf(json['day_type']);
    if (date is! String || version is! String || dayType == null) return null;

    final stops = <String, ShuttleStop>{
      for (final s in (json['stops'] as List).cast<Map>())
        s['id'] as String: ShuttleStop(
          name: s['name'] as String,
          lat: (s['lat'] as num?)?.toDouble(),
          lng: (s['lng'] as num?)?.toDouble(),
          boardingNote: s['boarding_note'] as String?,
        ),
    };

    final entries = <ShuttleDirection, List<ShuttleEntry>>{};
    final seen = <String>{};
    for (final route in (json['routes'] as List).cast<Map>()) {
      for (final d in (route['directions'] as List).cast<Map>()) {
        final id = d['id'] as String;
        final direction = _directionOf(id);
        if (direction == null) return null;
        seen.add(id);
        final stopNote = stops[d['from']]?.boardingNote;
        final list = entries.putIfAbsent(direction, () => []);
        for (final seg in (d['segments'] as List).cast<Map>()) {
          final entry = _entryOf(seg, stopNote);
          if (entry == null) return null;
          list.add(entry);
        }
      }
    }
    if (seen.length != 6) return null;

    final source = json['source'];
    return RemoteShuttleSchedule._(
      date: date,
      dayType: dayType,
      version: version,
      needsReview: source is Map && source['needs_review'] == true,
      stops: stops,
      entries: entries,
    );
  }

  /// 그날 운행이 없으면(`segments: []`) 미운행(null).
  ShuttleTimetable? timetableFor({
    required ShuttleRoute route,
    required ShuttleDirection direction,
  }) {
    final entries = _entries[direction];
    if (entries == null || entries.isEmpty) return null;
    return ShuttleTimetable(
      route: route,
      direction: direction,
      dayType: dayType,
      entries: entries,
    );
  }

  /// 서버 방향 id(고정 6개) → 앱 방향(1:1). 구간은 서버가 시작 시각 오름차순으로 준다.
  static ShuttleDirection? _directionOf(String id) => switch (id) {
    'main_out' => ShuttleDirection.schoolToJeongwang,
    'main_in' => ShuttleDirection.jeongwangToSchool,
    'campus2_out' => ShuttleDirection.schoolToCampus2,
    'campus2_in' => ShuttleDirection.campus2ToSchool,
    'campus2_from_station' => ShuttleDirection.jeongwangToCampus2,
    'campus2_to_station' => ShuttleDirection.campus2ToJeongwang,
    _ => null,
  };

  static ShuttleDayType? _dayTypeOf(Object? raw) => switch (raw) {
    'weekday' => ShuttleDayType.weekday,
    'saturday' => ShuttleDayType.saturday,
    'sunday' => ShuttleDayType.sunday,
    'holiday' => ShuttleDayType.holiday,
    _ => null,
  };

  /// 구간 → 시간표 항목. 도착버스 탑승의 승차 안내는 출발 정류장
  /// `boarding_note`, 없으면 구간 `note`를 쓴다.
  static ShuttleEntry? _entryOf(Map<dynamic, dynamic> seg, String? stopNote) {
    if (seg['type'] == 'fixed') {
      final time = _timeOf(seg['time']);
      return time == null ? null : ShuttleEntry.fixed(time);
    }
    final start = _timeOf(seg['start']);
    final end = _timeOf(seg['end']);
    if (start == null || end == null) return null;
    return switch (seg['type']) {
      'frequent' => ShuttleEntry.flexible(start, end),
      'arrival_board' => ShuttleEntry.arrivalBoarding(
        start,
        end,
        boardingNote: stopNote ?? seg['note'] as String? ?? '도착 버스 탑승',
      ),
      _ => null,
    };
  }

  /// "HH:MM" → [ShuttleTime]. 형식이 다르면 null.
  static ShuttleTime? _timeOf(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(raw);
    if (m == null) return null;
    final hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return ShuttleTime(hour, minute);
  }
}
