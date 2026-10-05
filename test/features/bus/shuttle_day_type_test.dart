import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/bus/data/data_source/korean_public_holidays.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';

void main() {
  group('dayTypeOf', () {
    test('평일', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 9, 8)),
        ShuttleDayType.weekday,
      ); // 화
    });

    test('토요일·일요일', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 9, 12)),
        ShuttleDayType.saturday,
      );
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 9, 13)),
        ShuttleDayType.holiday,
      );
    });

    test('평일 공휴일은 휴일 (한글날 금요일)', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 10, 9)),
        ShuttleDayType.holiday,
      );
    });

    test('대체공휴일도 휴일 (개천절 대체 월요일)', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 10, 5)),
        ShuttleDayType.holiday,
      );
    });

    test('토요일 공휴일은 토요일이 아니라 휴일 (추석 연휴 마지막 날)', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime(2026, 9, 26)),
        ShuttleDayType.holiday,
      );
    });

    test('목록 밖 연도는 요일만으로 판정', () {
      final d = DateTime(2030, 10, 9); // 한글날, 수요일
      expect(KoreanPublicHolidays.covers(d), isFalse);
      expect(ShuttleScheduleData.dayTypeOf(d), ShuttleDayType.weekday);
    });

    test('공휴일 목록이 앞으로 6개월은 남아 있다 (만료 전 갱신 알림용)', () {
      // 실패하면 korean_public_holidays.dart 에 다음 해 목록을 추가할 때다.
      final now = DateTime.now();
      expect(
        KoreanPublicHolidays.covers(now),
        isTrue,
        reason: '${now.year}년 공휴일 목록이 없다',
      );
      final later = now.add(const Duration(days: 180));
      expect(
        KoreanPublicHolidays.covers(later),
        isTrue,
        reason: '${later.year}년 공휴일 목록을 추가해야 한다',
      );
    });

    test('KST 벽시계(isUtc) 값도 같은 결과', () {
      expect(
        ShuttleScheduleData.dayTypeOf(DateTime.utc(2026, 12, 25, 9)),
        ShuttleDayType.holiday,
      );
    });
  });
}
