import 'package:handori/features/bus/data/data_source/korean_public_holidays.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

/// 셔틀버스 시간표 원본(하드코딩) 데이터 소스.
///
/// 출발 시각은 가독성을 위해 HHMM 정수(예: 1015 → 10:15) 리스트로 정의하고,
/// [_fixed] 헬퍼로 도메인 [ShuttleEntry]로 변환한다.
///
/// 2026-2학기(9.1 ~ 12.22) 학교 공지 이미지 기준. 학기마다 수동 갱신 필요.
///
/// 운행 정책 요약:
/// - 노선1(정왕역↔본교): 평일 전용. 토/일/공휴일 미운행.
/// - 노선2(제2캠퍼스↔본교·정왕역): 평일·토요일 운행. 일/공휴일 미운행.
class ShuttleScheduleData {
  const ShuttleScheduleData._();

  /// 도착버스 탑승 시간대(17:00 이후) 승차 위치 안내.
  /// 정해진 시간표 없이 정왕역에 도착한 버스를 그대로 탑승한다.
  static const String _arrivalBoardingNote = '파리바게뜨 건너편 하차장소(버스정류장)에서 도착 버스 탑승';

  // ── 노선1: 정왕역 → 학교 (등교) · 평일 ───────────────────────────────────
  // 2026-2학기(9.1 ~ 12.22) 기준.
  // 08:40~10:00 수시운행 → 10:00~16:50 정시 출발 → 17:00 이후 도착버스 탑승
  // (막차 약 22:17).
  static final List<ShuttleEntry> _route1UpWeekday = [
    const ShuttleEntry.flexible(ShuttleTime(8, 40), ShuttleTime(10, 0)),
    ..._fixed([
      1000, 1010, 1015, 1020, 1030, 1050, //
      1100, 1110, 1120, 1130, 1150, //
      1200, 1210, 1220, 1230, 1250, //
      1300, 1310, 1320, 1330, 1350, //
      1400, 1410, 1420, 1440, //
      1500, 1510, 1520, 1540, //
      1600, 1620, 1630, 1640, 1650,
    ]),
    ShuttleEntry.arrivalBoarding(
      const ShuttleTime(17, 0),
      const ShuttleTime(22, 17), // 막차 약 17분경
      boardingNote: _arrivalBoardingNote,
    ),
  ];

  // ── 노선1: 학교 → 정왕역 (하교) · 평일 ───────────────────────────────────
  // 2026-2학기(9.1 ~ 12.22) 기준.
  // 09:00~16:50 정시 출발 → 17:00~18:00 수시운행 → 18:00~22:40 정시 출발.
  static final List<ShuttleEntry> _route1DownWeekday = [
    ..._fixed([
      900, 920, 940, //
      1000, 1005, 1010, 1020, 1040, 1050, //
      1100, 1110, 1120, 1140, 1150, //
      1200, 1210, 1220, 1240, 1250, //
      1300, 1310, 1320, 1340, 1350, //
      1400, 1410, 1430, 1450, //
      1500, 1510, 1530, 1550, //
      1610, 1620, 1630, 1640, 1650,
    ]),
    const ShuttleEntry.flexible(ShuttleTime(17, 0), ShuttleTime(18, 0)),
    ..._fixed([
      1800, 1810, 1820, 1830, 1840, 1850, //
      1905, 1915, 1930, 1945, //
      2005, 2025, 2045, //
      2100, 2120, 2148, //
      2210, 2240,
    ]),
  ];

  // ── 노선2: 본교 → 제2캠퍼스 ─────────────────────────────────────────────
  // 평일 첫 2회(08:55, 09:00)는 정왕역 출발.
  static final List<ShuttleEntry> _route2ToCampusWeekday = _fixed([
    855, 900, 1000, 1100, 1200, 1300, //
    1400, 1500, 1600, 1700, 1800, 1900,
  ]);

  // 토요일: 정왕역 → 본교 → 제2캠퍼스.
  static final List<ShuttleEntry> _route2ToCampusSaturday = _fixed([
    845,
    850,
    900,
    905,
    910,
    915,
  ]);

  // ── 노선2: 제2캠퍼스 → 본교 ─────────────────────────────────────────────
  // 평일 17:40 편은 오이도역 경유.
  static final List<ShuttleEntry> _route2FromCampusWeekday = _fixed([
    940, 1030, 1130, 1230, 1330, 1430, //
    1530, 1630, 1740, 1830, 1930,
  ]);

  // 토요일: 제2캠퍼스 → 본교 → 정왕역.
  static final List<ShuttleEntry> _route2FromCampusSaturday = _fixed([
    1630,
    1645,
    1925,
    1928,
    1930,
    1935,
    1945,
  ]);

  /// HHMM 정수 리스트를 정시 출발 [ShuttleEntry] 리스트로 변환.
  static List<ShuttleEntry> _fixed(List<int> hhmmList) => hhmmList
      .map((hhmm) => ShuttleEntry.fixed(ShuttleTime.fromHhmm(hhmm)))
      .toList(growable: false);

  /// 날짜 → 요일 구분. 공휴일(대체공휴일 포함)과 일요일은
  /// [ShuttleDayType.holiday], 토요일은 [ShuttleDayType.saturday].
  /// 공휴일 목록에 없는 연도는 요일만으로 판정한다.
  static ShuttleDayType dayTypeOf(DateTime date) {
    // 목록 밖 연도는 요일만으로 판정한다. 목록이 만료되기 전에 알 수 있도록
    // shuttle_day_type_test 가 "지금 + 180일"이 목록 안인지 검사한다.
    if (KoreanPublicHolidays.isHoliday(date)) return ShuttleDayType.holiday;
    switch (date.weekday) {
      case DateTime.saturday:
        return ShuttleDayType.saturday;
      case DateTime.sunday:
        return ShuttleDayType.holiday;
      default:
        return ShuttleDayType.weekday;
    }
  }

  /// (노선·방향·요일)에 해당하는 시간표. 미운행이면 null.
  static ShuttleTimetable? timetableFor({
    required ShuttleRoute route,
    required ShuttleDirection direction,
    required ShuttleDayType dayType,
  }) {
    final entries = _entriesFor(route, direction, dayType);
    if (entries == null) return null;
    return ShuttleTimetable(
      route: route,
      direction: direction,
      dayType: dayType,
      entries: entries,
    );
  }

  static List<ShuttleEntry>? _entriesFor(
    ShuttleRoute route,
    ShuttleDirection direction,
    ShuttleDayType dayType,
  ) {
    if (route == ShuttleRoute.route1) {
      // 노선1은 평일 전용.
      if (dayType != ShuttleDayType.weekday) return null;
      switch (direction) {
        case ShuttleDirection.jeongwangToSchool:
          return _route1UpWeekday;
        case ShuttleDirection.schoolToJeongwang:
          return _route1DownWeekday;
        default:
          return null;
      }
    }

    // 노선2는 평일·토요일 운행.
    if (dayType == ShuttleDayType.holiday) return null;
    switch (direction) {
      case ShuttleDirection.schoolToCampus2:
        return dayType == ShuttleDayType.saturday
            ? _route2ToCampusSaturday
            : _route2ToCampusWeekday;
      case ShuttleDirection.campus2ToSchool:
        return dayType == ShuttleDayType.saturday
            ? _route2FromCampusSaturday
            : _route2FromCampusWeekday;
      default:
        return null;
    }
  }
}
