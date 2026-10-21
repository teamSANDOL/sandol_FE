/// 교시 시간표 (0시 기준 분). 백엔드 `/classrooms/available/periods` 가
/// 교시를 시각으로 바꿀 때 쓰는 표와 같다
/// (sandol_classroom_timetable `router/api.js`). 9교시부터 야간이라 간격이 다르다.
const List<({int start, int end})> classPeriods = [
  (start: 9 * 60 + 30, end: 10 * 60 + 20), // 1
  (start: 10 * 60 + 30, end: 11 * 60 + 20),
  (start: 11 * 60 + 30, end: 12 * 60 + 20),
  (start: 12 * 60 + 30, end: 13 * 60 + 20),
  (start: 13 * 60 + 30, end: 14 * 60 + 20),
  (start: 14 * 60 + 30, end: 15 * 60 + 20),
  (start: 15 * 60 + 30, end: 16 * 60 + 20),
  (start: 16 * 60 + 30, end: 17 * 60 + 20), // 8
  (start: 17 * 60 + 25, end: 18 * 60 + 15),
  (start: 18 * 60 + 15, end: 19 * 60 + 5),
  (start: 19 * 60 + 5, end: 19 * 60 + 55),
  (start: 20 * 60, end: 20 * 60 + 50),
  (start: 20 * 60 + 50, end: 21 * 60 + 40),
  (start: 21 * 60 + 40, end: 22 * 60 + 30), // 14
];

/// 1교시 시작 ~ 14교시 끝. 교시 선택의 '전체 교시'.
final ({int start, int end}) allPeriods = (
  start: classPeriods.first.start,
  end: classPeriods.last.end,
);

/// 조회 구간이 가리키는 교시 문구. 한 교시와 정확히 같으면 `N교시`,
/// 전체 교시면 `전체 교시`, 그 외(시각으로 고른 구간)는 null.
String? periodLabelOf(int startMinutes, int endMinutes) {
  if (startMinutes == allPeriods.start && endMinutes == allPeriods.end) {
    return '전체 교시';
  }
  for (var i = 0; i < classPeriods.length; i++) {
    final p = classPeriods[i];
    if (p.start == startMinutes && p.end == endMinutes) return '${i + 1}교시';
  }
  return null;
}
