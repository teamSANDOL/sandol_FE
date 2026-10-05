import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';

void main() {
  // 08:40~10:00 수시운행, 17:00~18:00 수시운행, 18:00 정시편.
  final timetable = ShuttleTimetable(
    route: ShuttleRoute.route1,
    direction: ShuttleDirection.schoolToJeongwang,
    dayType: ShuttleDayType.weekday,
    entries: const [
      ShuttleEntry.flexible(ShuttleTime(8, 40), ShuttleTime(10, 0)),
      ShuttleEntry.fixed(ShuttleTime(12, 30)),
      ShuttleEntry.flexible(ShuttleTime(17, 0), ShuttleTime(18, 0)),
      ShuttleEntry.fixed(ShuttleTime(18, 0)),
    ],
  );

  DateTime at(int h, int m) => DateTime.utc(2026, 9, 8, h, m);

  test('아직 시작 안 한 수시운행은 "운행 중"이 아니라 시작 시각 대기', () {
    final r = NextShuttleCalculator.calculate(timetable, at(6, 0));
    expect(r.status, ShuttleStatus.upcoming);
    expect(r.departureTime?.label, '08:40');
    expect(r.remainMinutes, 160);
    expect(r.subText, '08:40부터 수시운행');
  });

  test('구간 시작 정각부터는 수시운행', () {
    final r = NextShuttleCalculator.calculate(timetable, at(8, 40));
    expect(r.status, ShuttleStatus.flexible);
  });

  test('구간 안에서는 수시운행', () {
    final r = NextShuttleCalculator.calculate(timetable, at(9, 30));
    expect(r.status, ShuttleStatus.flexible);
    expect(r.subText, '08:40~10:00 수시운행');
  });

  test('구간 종료 정각(18:00)에는 같은 시각 정시편이 보인다', () {
    final r = NextShuttleCalculator.calculate(timetable, at(18, 0));
    expect(r.status, ShuttleStatus.upcoming);
    expect(r.departureTime?.label, '18:00');
    expect(r.remainMinutes, 0);
  });

  test('구간 종료(10:00) 직후에는 다음 정시편 카운트다운', () {
    final r = NextShuttleCalculator.calculate(timetable, at(10, 0));
    expect(r.status, ShuttleStatus.upcoming);
    expect(r.departureTime?.label, '12:30');
  });

  test('막차 이후에는 운행 종료', () {
    final r = NextShuttleCalculator.calculate(timetable, at(18, 1));
    expect(r.status, ShuttleStatus.closed);
  });

  test('시간표가 없으면 운행 안함', () {
    final r = NextShuttleCalculator.calculate(null, at(9, 0));
    expect(r.status, ShuttleStatus.notOperating);
  });

  group('upcoming', () {
    List<String> labels(DateTime now, {int count = 3}) =>
        NextShuttleCalculator.upcoming(
          timetable,
          now,
          count: count,
        ).map((e) => e.time.label).toList();

    test('진행 중인 구간부터 이후 항목을 순서대로', () {
      expect(labels(at(17, 30)), ['17:00', '18:00']);
    });

    test('지금 출발하는 정시편은 포함하고 지난 항목은 뺀다', () {
      expect(labels(at(12, 30)), ['12:30', '17:00', '18:00']);
      expect(labels(at(12, 31)), ['17:00', '18:00']);
    });

    test('개수를 넘기지 않는다', () {
      expect(labels(at(6, 0), count: 2), ['08:40', '12:30']);
    });

    test('막차 이후나 미운행이면 빈 목록', () {
      expect(labels(at(18, 1)), isEmpty);
      expect(NextShuttleCalculator.upcoming(null, at(9, 0)), isEmpty);
    });
  });
}
