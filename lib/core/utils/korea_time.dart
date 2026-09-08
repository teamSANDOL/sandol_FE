/// 한국 표준시(KST, UTC+9) 기준 "지금".
///
/// 셔틀 다음 출발, 오늘 식단, 빈 강의실 조회 요일·시각처럼 캠퍼스 기준으로
/// 판단해야 하는 값은 기기 시간대가 아니라 이 시각을 써야 한다. 교환학생
/// 기기나 해외 로밍 중 자동 시간대가 바뀐 기기에서 어긋나는 것을 막는다.
///
/// 반환값은 `isUtc == true` 인 [DateTime] 에 KST 벽시계 값을 실은 것이다.
/// `hour`·`minute`·`weekday`·`year/month/day` 는 한국 시각이고, 절대 시각
/// 비교(`isBefore` 등)에는 쓰지 않는다. 그런 비교는 `DateTime.now()` 그대로.
abstract final class KoreaTime {
  static const Duration offset = Duration(hours: 9);

  static DateTime now() => DateTime.now().toUtc().add(offset);
}
