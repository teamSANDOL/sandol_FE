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
      final q = ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 23, 48));
      expect(q.startMinutes, lessThan(q.endMinutes));
      expect(q.endMinutes, lessThanOrEqualTo(ClassroomQuery.hardEnd));
      expect(q.isAfterClassDay, isTrue);
    });

    test('nearestTickIndex', () {
      final ticks = ClassroomQuery.ticksFor(13 * 60 + 52);
      expect(ClassroomQuery.nearestTickIndex(ticks, 13 * 60 + 55), 0);
      expect(ClassroomQuery.nearestTickIndex(ticks, 15 * 60 + 40), 3); // 16시
      expect(ClassroomQuery.nearestTickIndex(ticks, 23 * 60), ticks.length - 1);
    });

    test('주말 판정', () {
      expect(ClassroomQuery.defaultFor(DateTime(2026, 9, 12)).isWeekend, isTrue);
      expect(ClassroomQuery.defaultFor(DateTime(2026, 9, 9)).isWeekend, isFalse);
    });
  });
}
