import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/home/model/schedule_event.dart';

void main() {
  final festival = ScheduleEvent(
    title: 'Techno Festival',
    start: DateTime(2026, 9, 29),
    end: DateTime(2026, 10, 1),
  );

  // 시각은 무시하고 날짜로만 센다
  DateTime on(int m, int d, [int h = 23]) => DateTime.utc(2026, m, d, h, 59);

  test('시작 전에는 D-N, 진행 중에는 D-Day', () {
    expect(festival.dDayOn(on(9, 19)), 'D-10');
    expect(festival.dDayOn(on(9, 28)), 'D-1');
    expect(festival.dDayOn(on(9, 29, 0)), 'D-Day');
    expect(festival.dDayOn(on(10, 1)), 'D-Day');
  });

  test('마지막 날까지는 끝나지 않은 일정', () {
    expect(festival.isOverOn(on(10, 1)), isFalse);
    expect(festival.isOverOn(on(10, 2, 0)), isTrue);
  });

  test('기간 표기, 하루짜리는 날짜 하나', () {
    expect(festival.periodLabel, '2026.09.29 ~ 2026.10.01');
    final oneDay = ScheduleEvent(
      title: '개교기념일',
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 5),
    );
    expect(oneDay.periodLabel, '2026.10.05');
  });
}
