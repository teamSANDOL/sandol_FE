import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/shuttle_transfer.dart';

/// 내장 시간표로 [direction]의 본교 환승 연결을 "출발→환승" 문자열로.
List<String> _connections(ShuttleDirection direction, DateTime now) {
  final (first, second, ride) = ShuttleTransfer.legsOf(direction)!;
  ShuttleTimetable? leg(ShuttleDirection d) => ShuttleScheduleData.timetableFor(
    route: d.route,
    direction: d,
    dayType: ShuttleScheduleData.dayTypeOf(now),
  );
  return [
    for (final c in ShuttleTransfer.connections(
      leg(first),
      leg(second),
      now,
      rideMinutes: ride,
    ))
      '${c.departure.label}→${c.transfer.label}',
  ];
}

void main() {
  // 2026-10-06(화) 평일.
  test('평일 정왕역 → 제2캠퍼스: 수시운행 구간에서 타도 연결하고, 같은 환승편은 늦은 출발을 남긴다', () {
    expect(
      _connections(
        ShuttleDirection.jeongwangToCampus2,
        DateTime.utc(2026, 10, 6, 8),
      ),
      ['08:40→10:00', '10:50→11:00', '11:50→12:00'],
    );
    // 수시운행 중(09:00)이면 지금 타는 것으로 본다.
    expect(
      _connections(
        ShuttleDirection.jeongwangToCampus2,
        DateTime.utc(2026, 10, 6, 9),
      ).first,
      '09:00→10:00',
    );
  });

  test('평일 제2캠퍼스 → 정왕역: 직행은 없고 환승만 있다', () {
    expect(
      ShuttleScheduleData.timetableFor(
        route: ShuttleRoute.route2,
        direction: ShuttleDirection.campus2ToJeongwang,
        dayType: ShuttleDayType.weekday,
      ),
      isNull,
    );
    expect(
      _connections(
        ShuttleDirection.campus2ToJeongwang,
        DateTime.utc(2026, 10, 6, 9),
      ),
      ['09:40→10:00', '10:30→10:50', '11:30→11:50'],
    );
  });

  test('2구간 막차 이후면 연결이 없다', () {
    expect(
      _connections(
        ShuttleDirection.jeongwangToCampus2,
        DateTime.utc(2026, 10, 6, 19, 30),
      ),
      isEmpty,
    );
    expect(
      _connections(
        ShuttleDirection.campus2ToJeongwang,
        DateTime.utc(2026, 10, 6, 19, 31),
      ),
      isEmpty,
    );
  });

  test('토요일: 직행편만 있고 환승 연결은 없다', () {
    final saturday = DateTime.utc(2026, 10, 10, 8);
    expect(
      ShuttleScheduleData.timetableFor(
        route: ShuttleRoute.route2,
        direction: ShuttleDirection.jeongwangToCampus2,
        dayType: ShuttleDayType.saturday,
      )!.entries.first.time.label,
      '08:45',
    );
    expect(
      _connections(ShuttleDirection.jeongwangToCampus2, saturday),
      isEmpty,
    );
  });

  test('본교를 거치지 않는 방향은 환승 대상이 아니다', () {
    expect(ShuttleTransfer.legsOf(ShuttleDirection.schoolToCampus2), isNull);
  });
}
