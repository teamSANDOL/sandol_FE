import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';

void main() {
  group('ClassroomQuery (시간 축, 1시간 디텐트)', () {
    test('디텐트는 지금 + 다음 정각부터 22:00 까지', () {
      final ticks = ClassroomQuery.ticksFor(13 * 60 + 52);
      expect(ticks.first, 13 * 60 + 52);
      expect(ticks[1], 14 * 60);
      expect(ticks.last, 22 * 60);
      expect(ticks.length, 1 + 9); // 14시~22시
    });

    test('defaultFor: 시작은 지금, 끝은 2시간 뒤에 가장 가까운 정각', () {
      final q = ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 13, 52)); // 월
      expect(q.dayName, '월요일');
      expect(q.anchorMinutes, 13 * 60 + 52);
      expect(q.startTime, '13:52');
      expect(q.endTime, '16:00');
      expect(q.timeLabel, '13:52 ~ 16:00');
    });

    test('밤늦게 정각이 없으면 한 칸을 만들어 준다', () {
      final ticks = ClassroomQuery.ticksFor(22 * 60 + 10);
      expect(ticks, [22 * 60 + 10, 23 * 60 + 10]);
    });

    test('21시가 넘으면 기본 조회는 내일 09시부터', () {
      for (final t in [
        DateTime(2026, 9, 7, 21, 30),
        DateTime(2026, 9, 7, 23, 48),
      ]) {
        final q = ClassroomQuery.defaultFor(t); // 월
        expect(q.daysAhead, 1);
        expect(q.dayName, '화요일');
        expect(q.timeLabel, '09:00 ~ 11:00');
        expect(q.ticks.length, 14); // 09시~22시, 손잡이를 움직일 수 있다
        expect(q.isAfterClassDay, isFalse);
      }
      expect(
        ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 20, 59)).isToday,
        isTrue,
      );
    });

    test('forDay: 일요일에서 이틀 뒤는 화요일, 오늘 선택 가능 여부', () {
      expect(
        ClassroomQuery.forDay(DateTime(2026, 9, 13, 10), 2).dayName,
        '화요일',
      );
      expect(
        ClassroomQuery.todaySelectable(DateTime(2026, 9, 7, 21, 59)),
        isTrue,
      );
      expect(ClassroomQuery.todaySelectable(DateTime(2026, 9, 7, 22)), isFalse);
    });

    test('nearestTickIndex', () {
      final ticks = ClassroomQuery.ticksFor(13 * 60 + 52);
      expect(ClassroomQuery.nearestTickIndex(ticks, 13 * 60 + 55), 0);
      expect(ClassroomQuery.nearestTickIndex(ticks, 15 * 60 + 40), 3); // 16시
      expect(ClassroomQuery.nearestTickIndex(ticks, 23 * 60), ticks.length - 1);
    });

    test('주말 판정', () {
      expect(
        ClassroomQuery.defaultFor(DateTime(2026, 9, 12)).isWeekend,
        isTrue,
      );
      expect(
        ClassroomQuery.defaultFor(DateTime(2026, 9, 9)).isWeekend,
        isFalse,
      );
    });
  });
}
