import 'package:flutter_test/flutter_test.dart';
import 'package:handol/features/empty_class/domain/model/classroom_query.dart';

void main() {
  group('ClassroomQuery (시간 축, 교시 시작·끝 디텐트)', () {
    test('디텐트는 지금 + 이후 교시 시작·끝 시각, 22:30 까지', () {
      final ticks = ClassroomQuery.ticksFor(13 * 60 + 52);
      expect(ticks.first, 13 * 60 + 52);
      expect(ticks[1], 14 * 60 + 20); // 5교시 끝
      expect(ticks[2], 14 * 60 + 30); // 6교시 시작
      expect(ticks.last, 22 * 60 + 30); // 14교시 끝
      expect(ticks.length, 1 + 15);
      // 30분에 시작하지 않는 저녁 교시도 칸이 된다
      expect(ticks, containsAll([17 * 60 + 25, 18 * 60 + 15, 21 * 60 + 40]));
      // 겹치는 시각(9교시 끝 = 10교시 시작)은 한 번만
      expect(ticks.where((t) => t == 18 * 60 + 15), hasLength(1));
    });

    test('defaultFor: 시작은 지금, 끝은 2시간 뒤에 가장 가까운 칸', () {
      final q = ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 13, 52)); // 월
      expect(q.dayName, '월요일');
      expect(q.anchorMinutes, 13 * 60 + 52);
      expect(q.startTime, '13:52');
      expect(q.endTime, '15:30');
      expect(q.timeLabel, '13:52 ~ 15:30');
    });

    test('밤늦게 칸이 없으면 한 칸을 만들어 준다', () {
      expect(ClassroomQuery.ticksFor(22 * 60 + 10), [
        22 * 60 + 10,
        22 * 60 + 30,
      ]);
      expect(ClassroomQuery.ticksFor(22 * 60 + 40), [
        22 * 60 + 40,
        23 * 60 + 10,
      ]);
    });

    test('마지막 교시(21:40)가 시작하면 기본 조회는 내일 1교시부터', () {
      for (final t in [
        DateTime(2026, 9, 7, 21, 40),
        DateTime(2026, 9, 7, 23, 48),
      ]) {
        final q = ClassroomQuery.defaultFor(t); // 월
        expect(q.daysAhead, 1);
        expect(q.dayName, '화요일');
        expect(q.timeLabel, '09:30 ~ 11:30');
        expect(q.ticks.length, 24); // 교시 시작·끝 28개 중 겹치는 4개 제외
        expect(q.isAfterClassDay, isFalse);
      }
      final late = ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 21, 39));
      expect(late.isToday, isTrue);
      expect(late.timeLabel, '21:39 ~ 22:30');
    });

    test('forDay: 일요일에서 이틀 뒤는 화요일, 오늘 선택 가능 여부', () {
      expect(
        ClassroomQuery.forDay(DateTime(2026, 9, 13, 10), 2).dayName,
        '화요일',
      );
      expect(
        ClassroomQuery.todaySelectable(DateTime(2026, 9, 7, 21, 39)),
        isTrue,
      );
      expect(
        ClassroomQuery.todaySelectable(DateTime(2026, 9, 7, 21, 40)),
        isFalse,
      );
    });

    test('nearestTickIndex', () {
      final ticks = ClassroomQuery.ticksFor(13 * 60 + 52);
      expect(ClassroomQuery.nearestTickIndex(ticks, 13 * 60 + 55), 0);
      expect(ClassroomQuery.nearestTickIndex(ticks, 15 * 60 + 40), 4); // 15:30
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
